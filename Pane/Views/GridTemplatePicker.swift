import SwiftUI

struct GridTemplateOption: Identifiable, Equatable {
    let id: String
    let label: String
    let zones: [ZonePosition]
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

let gridTemplateOptions: [GridTemplateOption] = [
    GridTemplateOption(id: "left-half+right-half", label: "Left | Right", zones: [.leftHalf, .rightHalf]),
    GridTemplateOption(id: "top-half+bottom-half", label: "Top | Bottom", zones: [.topHalf, .bottomHalf]),
    GridTemplateOption(id: "left-third+center-third+right-third", label: "Thirds", zones: [.leftThird, .centerThird, .rightThird]),
    GridTemplateOption(id: "left-third+right-two-thirds", label: "1/3 + 2/3", zones: [.leftThird, .rightTwoThirds]),
    GridTemplateOption(id: "left-two-thirds+right-third", label: "2/3 + 1/3", zones: [.leftTwoThirds, .rightThird]),
    GridTemplateOption(id: "top-left+top-right+bottom-left+bottom-right", label: "Quarters", zones: [.topLeft, .topRight, .bottomLeft, .bottomRight]),
    GridTemplateOption(id: "left-half+top-right+bottom-right", label: "Half + 2Q", zones: [.leftHalf, .topRight, .bottomRight]),
    GridTemplateOption(id: "maximize", label: "Full", zones: [.maximize]),
    GridTemplateOption(id: "custom", label: "Custom", zones: []),
]

let customGridTemplateID = "custom"

struct GridTemplatePicker: View {
    @Binding var selectedTemplate: GridTemplateOption?

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(gridTemplateOptions) { template in
                let selected = selectedTemplate?.id == template.id
                Button {
                    selectedTemplate = template
                } label: {
                    VStack(spacing: 3) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.15), lineWidth: selected ? 1.5 : 0.5)
                                .background(RoundedRectangle(cornerRadius: 4).fill(selected ? Color.accentColor.opacity(0.08) : Color.clear))
                                .frame(height: 36)

                            GeometryReader { geo in
                                let b = CGRect(x: 3, y: 3, width: geo.size.width - 6, height: geo.size.height - 6)
                                if template.zones.isEmpty {
                                    Image(systemName: "hand.draw")
                                        .font(.system(size: 14))
                                        .foregroundColor(selected ? .accentColor : .secondary)
                                        .position(x: b.midX, y: b.midY)
                                } else {
                                    ForEach(Array(template.zones.enumerated()), id: \.offset) { _, zone in
                                        let f = zone.frame(in: b)
                                        RoundedRectangle(cornerRadius: 1.5)
                                            .fill(selected ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.12))
                                            .frame(width: max(f.width - 1.5, 1), height: max(f.height - 1.5, 1))
                                            .position(x: f.midX, y: f.midY)
                                    }
                                }
                            }
                            .frame(height: 36)
                        }

                        Text(template.label)
                            .font(.system(size: 8))
                            .foregroundColor(selected ? .accentColor : .secondary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
