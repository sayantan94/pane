import SwiftUI
import AppKit

struct CustomLayoutEditor: View {
    @Binding var zones: [Zone]
    @State private var selectedIndex: Int?
    @State private var customApps: [CustomApp] = []
    @State private var dragStartFrame: CustomFrame?

    private let snapTargets: [CGFloat] = [0, 1.0/4, 1.0/3, 1.0/2, 2.0/3, 3.0/4, 1]
    private let snapTolerance: CGFloat = 0.02

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Drag zones to move. Drag the corner handles to resize.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    addZone()
                } label: {
                    Image(systemName: "plus.rectangle").font(.system(size: 12))
                }
                .buttonStyle(.plain)
                if let idx = selectedIndex, idx < zones.count {
                    Button {
                        zones.remove(at: idx)
                        selectedIndex = nil
                    } label: {
                        Image(systemName: "minus.rectangle").font(.system(size: 12)).foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            GeometryReader { geo in
                canvas(in: geo.size)
            }
            .frame(height: 200)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.05)))
        }
        .onAppear { customApps = CustomAppsStore().loadAll() }
    }

    private func canvas(in container: CGSize) -> some View {
        let aspect = screenAspect()
        let pad: CGFloat = 10
        let available = CGSize(width: container.width - pad * 2, height: container.height - pad * 2)
        let size = fitted(available: available, aspect: aspect)

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                .frame(width: size.width, height: size.height)

            ForEach(Array(zones.enumerated()), id: \.offset) { idx, _ in
                zoneView(index: idx, canvasSize: size)
            }
        }
        .frame(width: size.width, height: size.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func zoneView(index: Int, canvasSize: CGSize) -> some View {
        let zone = zones[index]
        if let frame = zone.customFrame {
            let x = frame.x * canvasSize.width
            let y = frame.y * canvasSize.height
            let w = max(frame.w * canvasSize.width, 30)
            let h = max(frame.h * canvasSize.height, 20)
            let isSelected = selectedIndex == index

            ZStack(alignment: .topLeading) {
                // Body. Only this area captures the move gesture.
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.accentColor.opacity(isSelected ? 0.32 : 0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.accentColor.opacity(isSelected ? 0.9 : 0.5),
                                        lineWidth: isSelected ? 1.5 : 1)
                        )

                    VStack(spacing: 3) {
                        if !zone.appBundleID.isEmpty,
                           let icon = AppIconProvider.shared.icon(for: zone.appBundleID) {
                            Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                        }
                        Text(zoneLabel(zone))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(zone.appBundleID.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                    }
                }
                .frame(width: w, height: h)
                .contentShape(Rectangle())
                .onTapGesture { selectedIndex = index }
                .gesture(moveGesture(index: index, canvasSize: canvasSize))

                // Resize handles on top, with higher priority so they win over the move gesture.
                resizeHandle(.right, index: index, canvasSize: canvasSize)
                    .offset(x: w - 7, y: h / 2 - 7)
                resizeHandle(.bottom, index: index, canvasSize: canvasSize)
                    .offset(x: w / 2 - 7, y: h - 7)
                resizeHandle(.bottomRight, index: index, canvasSize: canvasSize)
                    .offset(x: w - 7, y: h - 7)
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .offset(x: x, y: y)
        }
    }

    private enum Edge { case right, bottom, bottomRight }

    private func resizeHandle(_ edge: Edge, index: Int, canvasSize: CGSize) -> some View {
        let visible = selectedIndex == index
        return Rectangle()
            .fill(Color.accentColor)
            .frame(width: 14, height: 14)
            .cornerRadius(3)
            .opacity(visible ? 0.95 : 0.001)
            .contentShape(Rectangle())
            .gesture(resizeGesture(index: index, edge: edge, canvasSize: canvasSize))
    }

    private func moveGesture(index: Int, canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .onChanged { g in
                if dragStartFrame == nil {
                    dragStartFrame = zones[index].customFrame
                    selectedIndex = index
                }
                guard let start = dragStartFrame else { return }
                let dx = g.translation.width / canvasSize.width
                let dy = g.translation.height / canvasSize.height
                var newX = start.x + dx
                var newY = start.y + dy
                newX = max(0, min(1 - start.w, newX))
                newY = max(0, min(1 - start.h, newY))
                newX = snap(newX)
                newY = snap(newY)
                zones[index].customFrame = CustomFrame(x: newX, y: newY, w: start.w, h: start.h)
            }
            .onEnded { _ in dragStartFrame = nil }
    }

    private func resizeGesture(index: Int, edge: Edge, canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .onChanged { g in
                if dragStartFrame == nil {
                    dragStartFrame = zones[index].customFrame
                    selectedIndex = index
                }
                guard let start = dragStartFrame else { return }
                let dx = g.translation.width / canvasSize.width
                let dy = g.translation.height / canvasSize.height

                var newW = start.w
                var newH = start.h
                if edge == .right || edge == .bottomRight {
                    newW = max(0.05, min(1 - start.x, start.w + dx))
                    newW = snap(start.x + newW) - start.x
                }
                if edge == .bottom || edge == .bottomRight {
                    newH = max(0.05, min(1 - start.y, start.h + dy))
                    newH = snap(start.y + newH) - start.y
                }
                zones[index].customFrame = CustomFrame(x: start.x, y: start.y, w: newW, h: newH)
            }
            .onEnded { _ in dragStartFrame = nil }
    }

    private func snap(_ v: CGFloat) -> CGFloat {
        for target in snapTargets {
            if abs(v - target) < snapTolerance { return target }
        }
        return v
    }

    private func addZone() {
        let newZone = Zone(
            position: .custom,
            appBundleID: "",
            path: nil,
            displayIndex: 0,
            commands: nil,
            customFrame: CustomFrame(x: 0.1, y: 0.1, w: 0.4, h: 0.4),
            spaceIndex: nil
        )
        zones.append(newZone)
        selectedIndex = zones.count - 1
    }

    private func zoneLabel(_ z: Zone) -> String {
        if z.appBundleID.isEmpty { return "Empty" }
        if let app = customApps.first(where: { $0.bundleID == z.appBundleID }) { return app.name }
        return z.appBundleID
    }

    private func screenAspect() -> CGFloat {
        let frame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1200)
        return max(frame.width / frame.height, 0.5)
    }

    private func fitted(available: CGSize, aspect: CGFloat) -> CGSize {
        if available.width / aspect <= available.height {
            return CGSize(width: available.width, height: available.width / aspect)
        } else {
            return CGSize(width: available.height * aspect, height: available.height)
        }
    }
}
