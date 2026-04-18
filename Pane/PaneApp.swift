import SwiftUI
import AppKit
import Combine
import os

let paneLog = Logger(subsystem: "com.pane.app", category: "general")

func paneDebug(_ msg: String) {
    paneLog.warning("\(msg)")
    let path = NSHomeDirectory() + "/.config/pane/debug.log"
    let line = "\(Date()): \(msg)\n"
    if let handle = FileHandle(forWritingAtPath: path) {
        handle.seekToEndOfFile()
        handle.write(line.data(using: .utf8)!)
        handle.closeFile()
    } else {
        try? line.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

final class ExecutionStateHolder: ObservableObject {
    static let shared = ExecutionStateHolder()
    @Published var state: ExecutionState = .idle
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var welcomeWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private static let welcomeSeenKey = "hasSeenWelcome_v1"
    let executor = LayoutExecutor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }
        applyStatusIcon(for: .idle)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 340)
        popover.behavior = .transient

        ExecutionStateHolder.shared.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in self?.applyStatusIcon(for: state) }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        lastFingerprint = DisplayFingerprint.current()
        showWelcomeIfNeeded()
    }

    private var lastFingerprint: String = ""

    @objc private func screensDidChange() {
        let newFingerprint = DisplayFingerprint.current()
        guard newFingerprint != lastFingerprint else { return }
        lastFingerprint = newFingerprint

        paneDebug("[Pane] Screen arrangement changed → fingerprint=\(newFingerprint)")

        // Debounce: macOS sends multiple notifications during reconfiguration.
        autoApplyWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.applyMatchingLayout(for: newFingerprint)
        }
        autoApplyWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }

    private var autoApplyWork: DispatchWorkItem?

    private func applyMatchingLayout(for fingerprint: String) {
        let store = LayoutStore()
        guard let layouts = try? store.loadAll() else { return }
        guard let match = layouts.first(where: {
            ($0.autoApply ?? false) && $0.displayFingerprint == fingerprint
        }) else {
            paneDebug("[Pane] No auto-apply layout matches fingerprint=\(fingerprint)")
            return
        }
        paneDebug("[Pane] Auto-applying layout: \(match.name)")
        runLayout(match, onDisplay: 0)
    }

    private func applyStatusIcon(for state: ExecutionState) {
        guard let button = statusItem.button else { return }
        let symbol: String
        let tint: NSColor?
        switch state {
        case .idle:    symbol = "rectangle.split.2x2";           tint = nil
        case .running: symbol = "rectangle.split.2x2.fill";      tint = .controlAccentColor
        case .success: symbol = "checkmark.circle.fill";         tint = .systemGreen
        case .error:   symbol = "exclamationmark.triangle.fill"; tint = .systemOrange
        }
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Pane")
        image?.isTemplate = (tint == nil)
        button.image = image
        button.contentTintColor = tint
    }

    private func showWelcomeIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.welcomeSeenKey) else { return }
        let controller = NSHostingController(rootView: WelcomeView { [weak self] in
            UserDefaults.standard.set(true, forKey: Self.welcomeSeenKey)
            self?.welcomeWindow?.close()
            self?.welcomeWindow = nil
        })
        let window = NSWindow(contentViewController: controller)
        window.title = "Welcome to Pane"
        window.styleMask = [.titled, .closable]
        window.center()
        welcomeWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.contentViewController = NSHostingController(rootView: MenuBarView())
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func closePopover() {
        popover.performClose(nil)
    }

    func runLayout(_ layout: Layout, onDisplay displayIndex: Int) {
        paneDebug("[Pane] AppDelegate.runLayout called: \(layout.name), zones: \(layout.zones.count)")
        let holder = ExecutionStateHolder.shared
        holder.state = .running(layout.name)
        closePopover()

        Task.detached {
            paneDebug("[Pane] Task.detached starting execution")
            let result = await self.executor.execute(layout, onDisplay: displayIndex)
            paneDebug("[Pane] Execution done. successes: \(result.successes.count), errors: \(result.errors.count)")
            await MainActor.run {
                if result.isFullSuccess {
                    holder.state = .success("\(layout.name) — \(result.successes.count) windows")
                    Task {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        if case .success = holder.state { holder.state = .idle }
                    }
                } else if !result.errors.isEmpty {
                    let joined = result.errors.joined(separator: "\n")
                    holder.state = .error(joined)
                    if result.errors.contains(where: { PermissionsHelper.isAccessibilityError($0) }) {
                        self.showAccessibilityPrimer()
                    }
                } else {
                    holder.state = .idle
                }
            }
        }
    }

    private var accessibilityPrimerWindow: NSWindow?

    func showAccessibilityPrimer() {
        if let existing = accessibilityPrimerWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = AccessibilityPrimerView(
            onGranted: { [weak self] in
                self?.accessibilityPrimerWindow?.close()
                self?.accessibilityPrimerWindow = nil
            },
            onDismiss: { [weak self] in
                self?.accessibilityPrimerWindow?.close()
                self?.accessibilityPrimerWindow = nil
            }
        )
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "Pane needs Accessibility"
        window.styleMask = [.titled, .closable]
        window.center()
        accessibilityPrimerWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct PaneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            Text("Pane").frame(width: 200, height: 100)
        }
    }
}
