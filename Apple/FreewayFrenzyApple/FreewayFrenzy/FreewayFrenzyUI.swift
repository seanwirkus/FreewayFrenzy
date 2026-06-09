import SwiftUI

enum FreewayFrenzyUI {
    static let red = Color(red: 1.0, green: 0.27, blue: 0.21)
    static let mint = Color(red: 0.48, green: 1.0, blue: 0.66)
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.20)
    static let panel = Color(red: 0.09, green: 0.10, blue: 0.13)
    static let panelLight = Color(red: 0.20, green: 0.22, blue: 0.27)

    struct BlockPanel: ViewModifier {
        var radius: CGFloat = 14

        func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(panel.opacity(0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .stroke(.white.opacity(0.18), lineWidth: 2)
                        )
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(.black.opacity(0.35))
                                .frame(height: 8)
                                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                        }
                        .shadow(color: .black.opacity(0.45), radius: 0, x: 8, y: 9)
                )
        }
    }

    struct BlockButtonStyle: ButtonStyle {
        var fill: Color
        var foreground: Color = .white

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(foreground)
                .background(fill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.45), radius: 0, x: 4, y: 4)
                .scaleEffect(configuration.isPressed ? 0.94 : 1)
                .opacity(configuration.isPressed ? 0.86 : 1)
                .animation(.spring(response: 0.22, dampingFraction: 0.62), value: configuration.isPressed)
        }
    }

    struct PaintSwatch: View {
        let color: Color
        let isSelected: Bool

        var body: some View {
            Rectangle()
                .fill(color)
                .frame(width: 30, height: 24)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.black.opacity(0.25))
                        .frame(height: 5)
                }
                .overlay(
                    Rectangle()
                        .stroke(isSelected ? .white : .black.opacity(0.45), lineWidth: isSelected ? 3 : 1)
                )
                .shadow(color: isSelected ? color.opacity(0.65) : .clear, radius: 8)
        }
    }
}

extension View {
    func freewayBlockPanel(radius: CGFloat = 14) -> some View {
        modifier(FreewayFrenzyUI.BlockPanel(radius: radius))
    }
}
