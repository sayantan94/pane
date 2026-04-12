import SwiftUI

struct GridTemplateOption: Identifiable {
    let id: String
    let label: String
    let zones: [ZonePosition]
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
                GridTemplateCell(
                    template: template,
                    isSelected: selectedTemplate?.id == template.id
                )
                .onTapGesture { selectedTemplate = template }
            }
        }
    }
}

struct GridTemplateCell: View {
    let template: GridTemplateOption
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.primary.opacity(0.04))
                    .frame(width: 72, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isSelected ? warmAccent : Color.gray.opacity(0.2), lineWidth: isSelected ? 1.5 : 0.5)
                    )

                GeometryReader { geo in
                    let bounds = CGRect(x: 3, y: 3, width: geo.size.width - 6, height: geo.size.height - 6)
                    ForEach(Array(template.zones.enumerated()), id: \.offset) { _, zone in
                        let f = zone.frame(in: bounds)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSelected ? warmAccent.opacity(0.4) : Color.gray.opacity(0.15))
                            .frame(width: f.width - 1.5, height: f.height - 1.5)
                            .position(x: f.midX, y: f.midY)
                    }
                }
                .frame(width: 72, height: 44)
            }

            Text(template.label)
                .font(.system(size: 9))
                .foregroundColor(isSelected ? warmAccent : .secondary.opacity(0.7))
                .lineLimit(1)
        }
    }
}
