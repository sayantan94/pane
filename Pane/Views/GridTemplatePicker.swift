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
]

struct GridTemplatePicker: View {
    @Binding var selectedTemplate: GridTemplateOption?

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(gridTemplateOptions) { template in
                let selected = selectedTemplate?.id == template.id
                VStack(spacing: 4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: selected ? 2 : 1)
                            .frame(width: 76, height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selected ? Color.accentColor.opacity(0.1) : Color.clear)
                            )

                        GeometryReader { geo in
                            let b = CGRect(x: 4, y: 4, width: geo.size.width - 8, height: geo.size.height - 8)
                            ForEach(Array(template.zones.enumerated()), id: \.offset) { _, zone in
                                let f = zone.frame(in: b)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(selected ? Color.accentColor.opacity(0.4) : Color.secondary.opacity(0.15))
                                    .frame(width: max(f.width - 2, 1), height: max(f.height - 2, 1))
                                    .position(x: f.midX, y: f.midY)
                            }
                        }
                        .frame(width: 76, height: 46)
                    }

                    Text(template.label)
                        .font(.system(size: 9))
                        .foregroundColor(selected ? .accentColor : .secondary)
                        .lineLimit(1)
                }
                .onTapGesture { selectedTemplate = template }
            }
        }
    }
}
