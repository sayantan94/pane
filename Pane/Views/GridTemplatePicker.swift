import SwiftUI

struct GridTemplateOption: Identifiable {
    let id: String
    let label: String
    let zones: [ZonePosition]
}

let gridTemplateOptions: [GridTemplateOption] = [
    GridTemplateOption(id: "left-half+right-half", label: "Two Halves (Vertical)", zones: [.leftHalf, .rightHalf]),
    GridTemplateOption(id: "top-half+bottom-half", label: "Two Halves (Horizontal)", zones: [.topHalf, .bottomHalf]),
    GridTemplateOption(id: "left-third+center-third+right-third", label: "Three Thirds", zones: [.leftThird, .centerThird, .rightThird]),
    GridTemplateOption(id: "left-third+right-two-thirds", label: "Third + Two Thirds", zones: [.leftThird, .rightTwoThirds]),
    GridTemplateOption(id: "left-two-thirds+right-third", label: "Two Thirds + Third", zones: [.leftTwoThirds, .rightThird]),
    GridTemplateOption(id: "top-left+top-right+bottom-left+bottom-right", label: "Four Quarters", zones: [.topLeft, .topRight, .bottomLeft, .bottomRight]),
    GridTemplateOption(id: "left-half+top-right+bottom-right", label: "Half + Two Quarters", zones: [.leftHalf, .topRight, .bottomRight]),
    GridTemplateOption(id: "maximize", label: "Full Screen", zones: [.maximize]),
]

struct GridTemplatePicker: View {
    @Binding var selectedTemplate: GridTemplateOption?

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            ForEach(gridTemplateOptions) { template in
                GridTemplateCell(
                    template: template,
                    isSelected: selectedTemplate?.id == template.id
                )
                .onTapGesture {
                    selectedTemplate = template
                }
            }
        }
    }
}

struct GridTemplateCell: View {
    let template: GridTemplateOption
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )

                GeometryReader { geo in
                    ForEach(Array(template.zones.enumerated()), id: \.offset) { _, zone in
                        let zoneFrame = zone.frame(
                            in: CGRect(x: 2, y: 2, width: geo.size.width - 4, height: geo.size.height - 4)
                        )
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSelected ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2))
                            .frame(width: zoneFrame.width - 1, height: zoneFrame.height - 1)
                            .position(
                                x: zoneFrame.midX,
                                y: zoneFrame.midY
                            )
                    }
                }
                .frame(width: 80, height: 50)
            }

            Text(template.label)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}
