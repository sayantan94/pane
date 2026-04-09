import Carbon
import AppKit

final class HotkeyEngine {
    private var hotkeys: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    func register(shortcut: String, action: @escaping () -> Void) {
        guard let (modifiers, keyCode) = parseShortcut(shortcut) else {
            print("Invalid shortcut: \(shortcut)")
            return
        }

        let id = nextID
        nextID += 1
        hotkeys[id] = action

        let hotkeyID = EventHotKeyID(
            signature: OSType(0x50414E45), // "PANE"
            id: id
        )

        var hotkeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetEventDispatcherTarget(),
            0,
            &hotkeyRef
        )

        if status != noErr {
            print("Failed to register hotkey: \(shortcut)")
        }
    }

    func startListening() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let engine = userData.map({ Unmanaged<HotkeyEngine>.fromOpaque($0).takeUnretainedValue() }),
                  let event
            else {
                return OSStatus(eventNotHandledErr)
            }

            var hotkeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )

            engine.hotkeys[hotkeyID.id]?()
            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            handler,
            1,
            &eventSpec,
            selfPtr,
            &eventHandler
        )
    }

    private func parseShortcut(_ shortcut: String) -> (UInt32, UInt32)? {
        let parts = shortcut.lowercased().split(separator: "+").map(String.init)
        var modifiers: UInt32 = 0
        var key = ""

        for part in parts {
            switch part {
            case "ctrl", "control":
                modifiers |= UInt32(controlKey)
            case "option", "alt":
                modifiers |= UInt32(optionKey)
            case "cmd", "command":
                modifiers |= UInt32(cmdKey)
            case "shift":
                modifiers |= UInt32(shiftKey)
            default:
                key = part
            }
        }

        guard let keyCode = keyCodeMap[key] else { return nil }
        return (modifiers, keyCode)
    }

    private let keyCodeMap: [String: UInt32] = [
        "a": 0x00, "b": 0x0B, "c": 0x08, "d": 0x02, "e": 0x0E,
        "f": 0x03, "g": 0x05, "h": 0x04, "i": 0x22, "j": 0x26,
        "k": 0x28, "l": 0x25, "m": 0x2E, "n": 0x2D, "o": 0x1F,
        "p": 0x23, "q": 0x0C, "r": 0x0F, "s": 0x01, "t": 0x11,
        "u": 0x20, "v": 0x09, "w": 0x0D, "x": 0x07, "y": 0x10,
        "z": 0x06,
        "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "5": 0x17,
        "6": 0x16, "7": 0x1A, "8": 0x1C, "9": 0x19, "0": 0x1D,
        "left": 0x7B, "right": 0x7C, "up": 0x7E, "down": 0x7D,
        "space": 0x31, "return": 0x24, "tab": 0x30,
    ]
}
