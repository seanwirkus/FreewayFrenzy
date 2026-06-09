import SwiftUI

enum FreewayFrenzyUI {
    static let red = Color(red: 1.0, green: 0.27, blue: 0.21)
    static let mint = Color(red: 0.48, green: 1.0, blue: 0.66)
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.20)
    static let panel = Color(red: 0.09, green: 0.10, blue: 0.13)
    static let panelLight = Color(red: 0.20, green: 0.22, blue: 0.27)

    // Garage warm palette (FreewayFrenzyUI mock)
    static let garageBlockRadius: CGFloat = 2
    static let garageBackgroundTop = Color(red: 0.12, green: 0.08, blue: 0.03)
    static let garageBackgroundBottom = Color(red: 0.05, green: 0.04, blue: 0.02)
    static let garagePanel = Color(red: 0.14, green: 0.09, blue: 0.03).opacity(0.92)
    static let garageBorder = Color(red: 1.0, green: 0.71, blue: 0.31).opacity(0.22)
    static let garageAccent = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let garageAccentAlt = Color(red: 1.0, green: 0.42, blue: 0.21)
    static let garageLabel = Color(red: 0.63, green: 0.47, blue: 0.28)
    static let garageText = Color(red: 1.0, green: 0.96, blue: 0.88)

    static var garageBackground: LinearGradient {
        LinearGradient(
            colors: [garageBackgroundTop, garageBackgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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

    struct GaragePanelModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(garagePanel)
                .overlay(
                    RoundedRectangle(cornerRadius: garageBlockRadius, style: .continuous)
                        .stroke(garageBorder, lineWidth: 2)
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                }
                .shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: 4)
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

    struct GarageButtonStyle: ButtonStyle {
        var selected: Bool

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(selected ? garageAccent.opacity(0.2) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: garageBlockRadius, style: .continuous)
                        .stroke(selected ? garageAccent.opacity(0.5) : garageBorder.opacity(0.55), lineWidth: 2)
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
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

    struct SectionHeading: View {
        let icon: String
        let title: String

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(garageAccent)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(garageLabel)
                Rectangle()
                    .fill(garageBorder.opacity(0.65))
                    .frame(height: 2)
            }
        }
    }

    struct StatBar: View {
        let label: String
        let value: Int
        let color: Color

        var body: some View {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(garageLabel)
                    .frame(width: 28, alignment: .leading)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.black.opacity(0.4))
                            .overlay(Rectangle().stroke(garageBorder.opacity(0.5), lineWidth: 1))
                        HStack(spacing: 1) {
                            ForEach(0..<max(1, value / 8), id: \.self) { _ in
                                Rectangle()
                                    .fill(color)
                                    .overlay(alignment: .bottom) {
                                        Rectangle().fill(Color.black.opacity(0.25)).frame(height: 2)
                                    }
                            }
                        }
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                    }
                }
                .frame(height: 8)
                Text("\(value)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(garageLabel)
                    .frame(width: 24, alignment: .trailing)
            }
        }
    }

    struct BlockySlider: View {
        let label: String
        @Binding var value: Int
        var color: Color = garageAccent
        var icon: String = "car.fill"

        private let segments = 20

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label {
                        Text(label)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(garageText)
                    } icon: {
                        Image(systemName: icon)
                            .foregroundStyle(garageLabel)
                    }
                    Spacer()
                    Text(String(format: "%02d%%", value))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                }
                GeometryReader { geo in
                    let filled = Int(round(Double(value) / 100 * Double(segments)))
                    HStack(spacing: 2) {
                        ForEach(0..<segments, id: \.self) { index in
                            Rectangle()
                                .fill(index < filled ? color : Color.white.opacity(0.07))
                                .overlay(
                                    Rectangle()
                                        .stroke(index < filled ? color : garageBorder.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                    .frame(height: 10)
                    .overlay {
                        Slider(value: Binding(
                            get: { Double(value) },
                            set: { value = Int($0.rounded()) }
                        ), in: 0...100)
                        .tint(.clear)
                        .opacity(0.001)
                        .allowsHitTesting(true)
                    }
                }
                .frame(height: 24)
            }
        }
    }

    struct PressableButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.96 : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(.spring(response: 0.22, dampingFraction: 0.62), value: configuration.isPressed)
        }
    }

    struct BlockyToggle: View {
        let label: String
        let icon: String
        @Binding var isOn: Bool

        var body: some View {
            HStack {
                Label {
                    Text(label)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(garageText)
                } icon: {
                    Image(systemName: icon)
                        .foregroundStyle(garageLabel)
                }
                Spacer()
                Button {
                    isOn.toggle()
                } label: {
                    ZStack(alignment: isOn ? .trailing : .leading) {
                        RoundedRectangle(cornerRadius: garageBlockRadius, style: .continuous)
                            .fill(isOn ? garageAccent : Color.black.opacity(0.4))
                            .frame(width: 48, height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: garageBlockRadius, style: .continuous)
                                    .stroke(isOn ? garageAccent : garageBorder, lineWidth: 2)
                            )
                        RoundedRectangle(cornerRadius: garageBlockRadius, style: .continuous)
                            .fill(garageText)
                            .frame(width: 16, height: 16)
                            .padding(4)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .modifier(GaragePanelModifier())
        }
    }
}

extension View {
    func freewayBlockPanel(radius: CGFloat = 14) -> some View {
        modifier(FreewayFrenzyUI.BlockPanel(radius: radius))
    }

    func garagePanel() -> some View {
        modifier(FreewayFrenzyUI.GaragePanelModifier())
    }
}

enum GameSky {
    static let top = Color(red: 0.42, green: 0.74, blue: 0.95)
    static let bottom = Color(red: 0.74, green: 0.89, blue: 0.99)

    static var gradient: LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }
}
