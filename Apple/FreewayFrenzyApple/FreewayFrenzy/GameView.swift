import QuartzCore
import SceneKit
import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformColor = NSColor
typealias SCNFloat = CGFloat
#else
import UIKit
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformColor = UIColor
typealias SCNFloat = Float
#endif

fileprivate struct HUDSnapshot: Sendable, Equatable {
    let score: Int
    let highScore: Int
    let coins: Int
    let speed: Int
    let distance: Int
    let phase: GamePhase
    let throttle: CGFloat
    let carName: String
    let carColorR: Double
    let carColorG: Double
    let carColorB: Double
    let carRoofR: Double
    let carRoofG: Double
    let carRoofB: Double
    let selectedCarIndex: Int
}

@MainActor
final class GameHUDState: ObservableObject {
    @Published var score = 0
    @Published var highScore = 0
    @Published var coins = 0
    @Published var speed = 0
    @Published var distance = 0
    @Published var phase: GamePhase = .menu
    @Published var throttle: CGFloat = 0
    @Published var carName = ""
    @Published var carColor = Color.white
    @Published var carRoofColor = Color.black
    @Published var selectedCarIndex = 0

    /// Lets the SwiftUI overlay drive the game (Start / Retry / car carousel)
    /// through the same path as touch + keyboard input.
    weak var inputHandler: GameInputHandling?

    fileprivate func apply(_ snapshot: HUDSnapshot) {
        score = snapshot.score
        highScore = snapshot.highScore
        coins = snapshot.coins
        speed = snapshot.speed
        distance = snapshot.distance
        phase = snapshot.phase
        throttle = snapshot.throttle
        carName = snapshot.carName
        carColor = Color(
            red: snapshot.carColorR,
            green: snapshot.carColorG,
            blue: snapshot.carColorB
        )
        carRoofColor = Color(
            red: snapshot.carRoofR,
            green: snapshot.carRoofG,
            blue: snapshot.carRoofB
        )
        selectedCarIndex = snapshot.selectedCarIndex
    }
}

struct GameView: View {
    @StateObject private var state = GameHUDState()
    @State private var showGo = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sky gradient behind the GPU view: graceful fallback if SceneKit
                // is briefly empty, plus a little vertical depth.
                skyBackdrop

                LowPolyGameView(state: state, viewSize: geo.size)
                    .ignoresSafeArea()

                vignette

                GameHUDOverlay(state: state)

                if showGo {
                    goFlash
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }
            }
        }
        .ignoresSafeArea()
        .background(Color(red: 0.06, green: 0.09, blue: 0.16))
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: state.phase)
        .onChange(of: state.phase) { _, newPhase in
            if newPhase == .playing { flashGo() }
        }
        #if os(macOS)
        .padding(20)
        #endif
    }

    private var skyBackdrop: some View {
        LinearGradient(
            colors: [Color(red: 0.42, green: 0.74, blue: 0.95),
                     Color(red: 0.74, green: 0.89, blue: 0.99)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var vignette: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(0.3)],
            center: .center,
            startRadius: 160,
            endRadius: 640
        )
        .ignoresSafeArea()
        .blendMode(.multiply)
        .allowsHitTesting(false)
    }

    private var goFlash: some View {
        Text("GO!")
            .font(.system(size: 104, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 14, x: 0, y: 6)
            .allowsHitTesting(false)
    }

    private func flashGo() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { showGo = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) { showGo = false }
        }
    }
}

private let brandRed = FreewayFrenzyUI.red
private let brandMint = FreewayFrenzyUI.mint
private let brandGold = FreewayFrenzyUI.gold

struct GameHUDOverlay: View {
    @ObservedObject var state: GameHUDState

    private struct LayoutMetrics {
        let size: CGSize
        let compact: Bool
        let cramped: Bool
        let wide: Bool

        var horizontalPadding: CGFloat {
            #if os(macOS)
            return 44
            #else
            return compact ? 14 : 20
            #endif
        }

        var topPadding: CGFloat {
            #if os(macOS)
            return 24
            #else
            return cramped ? 4 : 8
            #endif
        }

        var bottomPadding: CGFloat {
            #if os(macOS)
            return 28
            #else
            return compact ? 10 : 16
            #endif
        }

        var cardOuterPadding: CGFloat {
            #if os(macOS)
            return 56
            #else
            return compact ? 10 : 16
            #endif
        }

        var cardInnerPadding: CGFloat {
            #if os(macOS)
            return 34
            #else
            return compact ? 16 : 22
            #endif
        }

        var titleFontSize: CGFloat {
            #if os(macOS)
            return 44
            #else
            return cramped ? 28 : (compact ? 32 : 38)
            #endif
        }

        var cardMaxWidth: CGFloat {
            #if os(macOS)
            return 600
            #else
            return min(max(size.width - cardOuterPadding * 2, 320), wide ? 560 : 430)
            #endif
        }

        var previewScale: CGFloat {
            #if os(macOS)
            return 1.08
            #else
            return cramped ? 0.82 : (wide ? 1.12 : 1.0)
            #endif
        }

        var swatchColumns: Int {
            wide ? 6 : 4
        }

        var menuSpacing: CGFloat {
            cramped ? 10 : 15
        }
    }

    private func metrics(for size: CGSize) -> LayoutMetrics {
        LayoutMetrics(
            size: size,
            compact: size.width < 430 || size.height < 760,
            cramped: size.height < 670,
            wide: size.width >= 560
        )
    }

    private var hudHorizontalPadding: CGFloat {
        #if os(macOS)
        44
        #else
        20
        #endif
    }

    private var hudTopPadding: CGFloat {
        #if os(macOS)
        24
        #else
        6
        #endif
    }

    private var hudBottomPadding: CGFloat {
        #if os(macOS)
        28
        #else
        12
        #endif
    }

    private var cardOuterPadding: CGFloat {
        #if os(macOS)
        56
        #else
        14
        #endif
    }

    private var cardInnerPadding: CGFloat {
        #if os(macOS)
        34
        #else
        22
        #endif
    }

    private var titleFontSize: CGFloat {
        #if os(macOS)
        44
        #else
        36
        #endif
    }

    private var cardMaxWidth: CGFloat {
        #if os(macOS)
        560
        #else
        430
        #endif
    }

    private var paintStyles: [CarStyle] {
        CarStyle.catalog
    }

    var body: some View {
        GeometryReader { geo in
            let layout = metrics(for: geo.size)
            ZStack {
                switch state.phase {
                case .playing, .crash:
                    playingHUD(layout)
                case .menu:
                    menuCard(layout)
                case .gameOver:
                    gameOverCard(layout)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var controlHint: String {
        #if os(macOS)
        return "← → change lanes  ·  W / ↑ boost  ·  S / ↓ brake"
        #else
        return "Swipe to change lanes · hold up to boost"
        #endif
    }

    // MARK: Playing

    private func playingHUD(_ layout: LayoutMetrics) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(state.speed)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("km/h")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    statusChip
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    statPill(icon: "rosette", value: "\(state.score)", tint: .white)
                    statPill(icon: "trophy.fill", value: "\(state.highScore)", tint: brandGold)
                    statPill(icon: "circle.circle.fill", value: "\(state.coins)", tint: brandGold)
                        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: state.coins)
                }
            }
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.top, layout.topPadding)

            Spacer()

            #if os(macOS)
            macControlBar
                .padding(.horizontal, layout.horizontalPadding)
                .padding(.bottom, layout.bottomPadding)
                .opacity(state.phase == .playing ? 1 : 0)
            #else
            Text(controlHint)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial, in: Capsule())
                .safeAreaPadding(.bottom, layout.bottomPadding)
                .opacity(state.phase == .playing ? 1 : 0)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    #if os(macOS)
    private var macControlBar: some View {
        HStack(spacing: 10) {
            macKeyChip("←", label: "Left")
            macKeyChip("→", label: "Right")
            Spacer()
            macKeyChip("W", label: "Boost")
            macKeyChip("S", label: "Brake")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.1), lineWidth: 1))
    }

    private func macKeyChip(_ key: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(key)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 34, minHeight: 30)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
    #endif

    private var statusChip: some View {
        let isBoost = state.throttle > 30
        let isBrake = state.throttle < -30
        let label = isBoost ? "BOOST" : (isBrake ? "BRAKE" : "CRUISE")
        let tint: Color = isBoost ? brandRed : (isBrake ? .blue : brandMint)
        return Text(label)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(tint.opacity(0.16), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.5), lineWidth: 1))
    }

    private func statPill(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: Shared chrome

    private func titleStack(_ layout: LayoutMetrics) -> some View {
        VStack(spacing: -8) {
            Text("FREEWAY")
                .foregroundStyle(brandRed)
            Text("FRENZY")
                .foregroundStyle(.white)
        }
        .font(.system(size: layout.titleFontSize, weight: .black, design: .rounded))
        .tracking(1)
        // Hard offset drop-shadow for a chunky, sticker-like title.
        .shadow(color: .black.opacity(0.3), radius: 0, x: 3, y: 4)
    }

    private func cardBackground(cornerRadius: CGFloat = 30) -> some View {
        Color.clear.freewayBlockPanel(radius: 14)
    }

    private func pillButton(_ title: String, icon: String, fill: Color, fg: Color = .black, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 19, weight: .black, design: .rounded))
            .foregroundStyle(fg)
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .background(fill, in: Capsule())
            .shadow(color: fill.opacity(0.5), radius: 14, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: Menu

    private func menuCard(_ layout: LayoutMetrics) -> some View {
        let content = VStack(spacing: layout.menuSpacing) {
            titleStack(layout)

            VStack(spacing: layout.cramped ? 8 : 12) {
                Text("BLOCK GARAGE")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(brandGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 4, style: .continuous))

                HStack(spacing: layout.cramped ? 12 : 20) {
                    carArrow("chevron.left", direction: -1)
                    carPreview(scale: layout.previewScale)
                    carArrow("chevron.right", direction: 1)
                }

                HStack(spacing: 8) {
                    Text(state.carName.uppercased())
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("PAINT")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.75))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(brandGold, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                    Text("CAR \(min(max(state.selectedCarIndex + 1, 1), paintStyles.count))/\(paintStyles.count)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                }

                paintGrid(columns: layout.swatchColumns)
            }

            pillButton("PLAY", icon: "play.fill", fill: brandMint) {
                state.inputHandler?.tap()
            }

            if !layout.cramped {
                Text(controlHint)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            }

            if state.highScore > 0 {
                Label("Best \(state.highScore)", systemImage: "trophy.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(brandGold)
            }
        }

        return ScrollView(.vertical, showsIndicators: false) {
            content
                .padding(layout.cardInnerPadding)
                .frame(maxWidth: layout.cardMaxWidth)
                .background { cardBackground() }
                .padding(layout.cardOuterPadding)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .safeAreaPadding(.top, layout.topPadding)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    private func paintGrid(columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 58, maximum: 86), spacing: 8), count: columns), spacing: 8) {
            ForEach(Array(paintStyles.enumerated()), id: \.offset) { index, style in
                Button {
                    state.inputHandler?.selectCar(index)
                } label: {
                    paintTile(style: style, isSelected: index == state.selectedCarIndex)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(8)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func paintTile(style: CarStyle, isSelected: Bool) -> some View {
        let body = Color(hex: style.bodyHex)
        let roof = Color(hex: style.roofHex)
        return VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                FreewayFrenzyUI.PaintSwatch(color: body, isSelected: isSelected)
                    .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(roof)
                    .frame(width: 16, height: 9)
                    .overlay(Rectangle().stroke(.black.opacity(0.45), lineWidth: 1))
                    .offset(x: -4, y: 4)
            }

            Text(style.name.uppercased())
                .font(.system(size: 8.5, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 6)
        .frame(minHeight: 58)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? body.opacity(0.22) : .white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(isSelected ? .white.opacity(0.85) : .white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        )
    }

    private func carArrow(_ icon: String, direction: Int) -> some View {
        Button {
            state.inputHandler?.swipeLane(direction)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
        }
        .buttonStyle(FreewayFrenzyUI.BlockButtonStyle(fill: FreewayFrenzyUI.panelLight))
    }

    /// A tiny blocky car built from SwiftUI shapes, tinted with the chosen colour.
    private func carPreview(scale: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(0.28))
                .frame(width: 128, height: 20)
                .offset(y: 42)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(state.carColor)
                .frame(width: 126, height: 58)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.black.opacity(0.23))
                        .frame(height: 16)
                }
                .shadow(color: state.carColor.opacity(0.65), radius: 12)

            Rectangle()
                .fill(state.carRoofColor)
                .frame(width: 84, height: 34)
                .offset(y: -21)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.16))
                        .frame(height: 7)
                }

            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(red: 0.55, green: 0.78, blue: 0.92).opacity(0.78))
                    .frame(width: 28, height: 16)
                Rectangle()
                    .fill(Color(red: 0.18, green: 0.33, blue: 0.46).opacity(0.9))
                    .frame(width: 22, height: 16)
            }
            .offset(y: -21)

            Rectangle()
                .fill(.black.opacity(0.38))
                .frame(width: 132, height: 8)
                .offset(y: 9)

            HStack(spacing: 48) {
                Rectangle().fill(.yellow).frame(width: 10, height: 8)
                Rectangle().fill(.yellow).frame(width: 10, height: 8)
            }
            .offset(y: 21)

            HStack(spacing: 66) {
                Circle()
                    .fill(.black)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().fill(.white.opacity(0.55)).frame(width: 8, height: 8))
                Circle()
                    .fill(.black)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().fill(.white.opacity(0.55)).frame(width: 8, height: 8))
            }
            .offset(y: 32)
        }
        .frame(width: 138, height: 86)
        .scaleEffect(scale)
        .frame(width: 138 * scale, height: 86 * scale)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.carColor)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.carRoofColor)
    }

    // MARK: Game Over

    private func gameOverCard(_ layout: LayoutMetrics) -> some View {
        VStack(spacing: 13) {
            Text("GAME OVER")
                .font(.system(size: layout.titleFontSize, weight: .black, design: .rounded))
                .foregroundStyle(brandRed)
                .shadow(color: .black.opacity(0.3), radius: 0, x: 3, y: 4)

            if state.score > 0 && state.score >= state.highScore {
                Label("NEW BEST!", systemImage: "sparkles")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(brandGold)
            }

            VStack(spacing: 10) {
                resultRow(label: "Score", value: "\(state.score)", tint: .white)
                resultRow(label: "Best", value: "\(state.highScore)", tint: brandGold)
                resultRow(label: "Distance", value: "\(state.distance) m", tint: .white.opacity(0.8))
            }
            .padding(.vertical, 2)

            HStack(spacing: 12) {
                pillButton("RETRY", icon: "arrow.clockwise", fill: brandMint) {
                    state.inputHandler?.tap()
                }
                pillButton("MENU", icon: "house.fill", fill: .white.opacity(0.16), fg: .white) {
                    state.inputHandler?.pressMenu()
                }
            }
            .padding(.top, 4)
        }
        .padding(layout.cardInnerPadding)
        .frame(maxWidth: layout.cardMaxWidth)
        .background { cardBackground() }
        .padding(layout.cardOuterPadding)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    private func resultRow(label: String, value: String, tint: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .frame(width: 230)
    }
}

/// Springy press feedback for the menu / game-over buttons.
private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct LowPolyGameView: PlatformViewRepresentable {
    let state: GameHUDState
    let viewSize: CGSize

    #if os(macOS)
    func makeNSView(context: Context) -> GameSCNView {
        makeView(context: context)
    }

    func updateNSView(_ view: GameSCNView, context: Context) {
        context.coordinator.setAspect(size: viewSize)
    }
    #else
    func makeUIView(context: Context) -> GameSCNView {
        makeView(context: context)
    }

    func updateUIView(_ view: GameSCNView, context: Context) {
        context.coordinator.setAspect(size: viewSize)
    }
    #endif

    func makeCoordinator() -> LowPolyGameCoordinator {
        LowPolyGameCoordinator(state: state)
    }

    private func makeView(context: Context) -> GameSCNView {
        let view = GameSCNView(frame: .zero)
        view.backgroundColor = PlatformColor(red: 0.45, green: 0.72, blue: 0.88, alpha: 1)
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.rendersContinuously = true
        view.allowsCameraControl = false
        view.scene = context.coordinator.scene
        view.delegate = context.coordinator
        view.gameInputHandler = context.coordinator
        context.coordinator.attach(to: view)
        return view
    }
}

protocol GameInputHandling: AnyObject {
    func pressStart()
    func pressMenu()
    func setSteer(_ value: CGFloat)
    func setThrottle(_ value: CGFloat)
    func touchDown()
    func tap()
    func swipeLane(_ direction: Int)
    func selectCar(_ index: Int)
    func dragThrottle(_ deltaY: CGFloat)
    func touchUp()
}

final class LowPolyGameCoordinator: NSObject, SCNSceneRendererDelegate, GameInputHandling {
    // MARK: Layout tuning — all world-space, easy to tweak in one place.
    /// World distance between neighbouring lane centres. Bigger = chunkier road.
    static let laneSpacing: CGFloat = 2.4
    /// Where the player car sits along Z (closer to camera = lower on screen).
    static let playerZ: CGFloat = 3.8
    /// World Z travelled per unit of logic-space Y. Fresh traffic starts behind
    /// the fog line, then moves in smoothly instead of popping mid-screen.
    static let zPerLogic: CGFloat = 0.13
    #if os(macOS)
    static let playerScale: CGFloat = 1.18
    #else
    static let playerScale: CGFloat = 1.34
    #endif

    let scene = SCNScene()
    private let hudState: GameHUDState

    private let model = GameModel()
    private let sound = SoundController()
    private var input = GameInput()
    private var lastTime: TimeInterval = 0
    private var lastPhase: GamePhase = .menu
    private var lastCoinsCollected = 0
    private var lastSteerMagnitude: CGFloat = 0
    private var lastHUDSnapshot: HUDSnapshot?
    private var cachedAspect: CGFloat = 0.46
    private var simulationTime: TimeInterval = 0

    private let world = SCNNode()
    private let roadRoot = SCNNode()
    private let sceneryRoot = SCNNode()
    private let obstacleRoot = SCNNode()
    private let coinRoot = SCNNode()
    private let debrisRoot = SCNNode()
    private let playerNode = SCNNode()
    private let cameraNode = SCNNode()
    
    private let ambientNode = SCNNode()
    private let sunNode = SCNNode()

    private var obstacleNodes: [SCNNode] = []
    private var coinNodes: [SCNNode] = []
    private var roadSegments: [SCNNode] = []
    private var laneDashNodes: [SCNNode] = []
    private var sceneryNodes: [SCNNode] = []
    private var debrisNodes: [SCNNode] = []
    private weak var view: SCNView?
    private var renderedPlayerCarIndex: Int?

    private struct CameraProfile {
        let height: CGFloat
        let back: CGFloat
        let pitch: CGFloat
        let fov: CGFloat
        let fogStart: CGFloat
        let fogEnd: CGFloat
        let speedLift: CGFloat
        let speedBack: CGFloat
    }

    private var cameraProfile: CameraProfile {
        #if os(macOS)
        return CameraProfile(height: 8.6, back: 14.6, pitch: -0.39, fov: 52, fogStart: 64, fogEnd: 126, speedLift: 0.48, speedBack: 1.05)
        #else
        if cachedAspect > 0.9 {
            return CameraProfile(height: 6.4, back: 9.6, pitch: -0.57, fov: 45, fogStart: 38, fogEnd: 76, speedLift: 0.28, speedBack: 0.45)
        } else {
            return CameraProfile(height: 5.25, back: 7.15, pitch: -0.72, fov: 39, fogStart: 28, fogEnd: 58, speedLift: 0.18, speedBack: 0.18)
        }
        #endif
    }

    init(state: GameHUDState) {
        self.hudState = state
        super.init()
    }

    @MainActor
    func attach(to view: SCNView) {
        guard self.view == nil else { return }
        self.view = view
        hudState.inputHandler = self
        refreshAspect(from: view)
        buildScene()
        view.pointOfView = cameraNode
    }

    @MainActor
    func refreshAspect(from view: SCNView) {
        guard view.bounds.height > 0 else { return }
        setAspect(size: view.bounds.size)
    }

    func setAspect(size: CGSize) {
        guard size.height > 0 else { return }
        cachedAspect = size.width / size.height
        applyCameraProfile(animated: false)
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let delta = lastTime == 0 ? 0 : time - lastTime
        lastTime = time
        simulationTime = time

        model.update(deltaTime: delta, now: time, input: input)
        syncAudio()
        updateWorld(time: time)
        updateHUD()

        input.startPressed = false
        input.menuPressed = false
    }

    func pressStart() {
        input.startPressed = true
    }

    func pressMenu() {
        input.menuPressed = true
    }

    func setSteer(_ value: CGFloat) {
        input.steer = value
        #if os(iOS)
        if abs(value) > 60, lastSteerMagnitude < 60 {
            Task { @MainActor in GameHaptics.laneChange() }
        }
        lastSteerMagnitude = abs(value)
        #endif
    }

    func setThrottle(_ value: CGFloat) {
        input.throttle = value
    }

    func touchDown() {}

    func tap() {
        if model.phase == .menu || model.phase == .gameOver {
            pressStart()
        }
    }

    func swipeLane(_ direction: Int) {
        let previousLane = model.targetLane
        let previousCar = model.selectedCarIndex
        model.nudgeLane(direction, now: simulationTime > 0 ? simulationTime : CACurrentMediaTime())
        if model.phase == .playing, model.targetLane != previousLane {
            sound.playLane()
            #if os(iOS)
            Task { @MainActor in GameHaptics.laneChange() }
            #endif
        } else if model.phase == .menu, model.selectedCarIndex != previousCar {
            sound.playTap()
        }
    }

    func selectCar(_ index: Int) {
        let previousCar = model.selectedCarIndex
        model.selectCar(index)
        if model.selectedCarIndex != previousCar {
            sound.playTap()
        }
    }

    func dragThrottle(_ deltaY: CGFloat) {
        guard model.phase == .playing else { return }
        let previous = input.throttle
        if deltaY < -28 {
            input.throttle = 100
        } else if deltaY > 28 {
            input.throttle = -100
        } else {
            input.throttle = 0
        }
        if input.throttle > 60, previous <= 60 {
            sound.playBoost()
        }
    }

    func touchUp() {
        input.steer = 0
        input.throttle = 0
        lastSteerMagnitude = 0
    }

    private func syncAudio() {
        if model.phase == .playing {
            sound.setEngineSpeed(model.speed)
            if lastPhase != .playing {
                sound.playStart()
            }
        } else {
            sound.stopEngine()
        }

        if model.phase == .crash, lastPhase == .playing {
            sound.playCrash()
            #if os(iOS)
            Task { @MainActor in GameHaptics.crash() }
            #endif
        }
        lastPhase = model.phase

        if model.coinsCollected > lastCoinsCollected {
            sound.playCoin()
            #if os(iOS)
            Task { @MainActor in GameHaptics.coin() }
            #endif
            lastCoinsCollected = model.coinsCollected
        }

        if model.phase == .menu {
            lastCoinsCollected = 0
        }
    }

    private func buildScene() {
        let sky = PlatformColor.sky
        scene.background.contents = sky
        // Bright close fog keeps spawn-in hidden while avoiding the endless-highway
        // look on iPhone. The player now sits much larger in frame.
        let profile = cameraProfile
        scene.fogStartDistance = profile.fogStart
        scene.fogEndDistance = profile.fogEnd
        scene.fogDensityExponent = 1.4
        scene.fogColor = sky

        world.name = "world"
        scene.rootNode.addChildNode(world)
        world.addChildNode(roadRoot)
        world.addChildNode(sceneryRoot)
        world.addChildNode(obstacleRoot)
        world.addChildNode(coinRoot)
        world.addChildNode(debrisRoot)
        world.addChildNode(playerNode)

        buildLighting()
        buildCamera()
        buildRoad()
        buildScenery()
        buildPlayer()
        buildObstacles()
        buildCoins()
    }

    private func buildLighting() {
        // Bright, flat-ish daylight that keeps the blocky colours saturated and
        // readable. No day/night cycle — that was driving the scene to black.
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.intensity = 720
        ambientNode.light?.color = PlatformColor(red: 0.86, green: 0.92, blue: 0.98, alpha: 1)
        scene.rootNode.addChildNode(ambientNode)

        sunNode.light = SCNLight()
        sunNode.light?.type = .directional
        sunNode.light?.intensity = 1150
        sunNode.light?.color = PlatformColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1)
        sunNode.light?.castsShadow = true
        sunNode.light?.shadowMode = .deferred
        sunNode.light?.shadowRadius = 7
        sunNode.light?.shadowColor = PlatformColor(white: 0, alpha: 0.28)
        sunNode.eulerAngles = SCNVector3(-CGFloat.pi / 3.2, -CGFloat.pi / 4.8, 0)
        scene.rootNode.addChildNode(sunNode)
    }

    private func buildCamera() {
        let cam = SCNCamera()
        cam.usesOrthographicProjection = false
        cam.fieldOfView = cameraProfile.fov
        cam.projectionDirection = .horizontal
        cam.zNear = 0.5
        cam.zFar = 600
        cam.wantsHDR = true
        // A touch of bloom keeps the coins / lights glowing without washing the
        // flat blocky colours out. SSAO removed — it muddied the hard edges.
        cam.bloomIntensity = 0.45
        cam.bloomThreshold = 0.78
        cam.bloomBlurRadius = 8
        cam.wantsExposureAdaptation = false
        cam.vignettingIntensity = 0.18
        cam.vignettingPower = 1.1
        cameraNode.camera = cam
        applyCameraProfile(animated: false)
        scene.rootNode.addChildNode(cameraNode)
    }

    private func applyCameraProfile(animated: Bool) {
        let profile = cameraProfile
        cameraNode.camera?.fieldOfView = profile.fov
        scene.fogStartDistance = profile.fogStart
        scene.fogEndDistance = profile.fogEnd
        let targetPosition = SCNVector3(0, SCNFloat(profile.height), SCNFloat(Self.playerZ + profile.back))
        let targetAngles = SCNVector3(SCNFloat(profile.pitch), 0, 0)
        if animated {
            cameraNode.position.x += (targetPosition.x - cameraNode.position.x) * 0.12
            cameraNode.position.y += (targetPosition.y - cameraNode.position.y) * 0.12
            cameraNode.position.z += (targetPosition.z - cameraNode.position.z) * 0.12
            cameraNode.eulerAngles.x += (targetAngles.x - cameraNode.eulerAngles.x) * 0.12
        } else {
            cameraNode.position = targetPosition
            cameraNode.eulerAngles = targetAngles
        }
    }

    private func buildRoad() {
        let roadWidth = Self.laneSpacing * 5.25      // covers all 5 lanes + margin
        let halfRoad = roadWidth / 2

        for index in 0..<18 {
            let segment = slab(width: roadWidth, height: 0.2, length: 5.2, color: .road, chamfer: 0.01)
            segment.position = SCNVector3(0, -0.1, CGFloat(index) * -5.2)
            roadRoot.addChildNode(segment)
            roadSegments.append(segment)
        }

        // Chunky dashed lane markers between each pair of lanes. Extra coverage
        // keeps the near ground and fog line filled in perspective.
        for lane in 1..<model.laneCount {
            for index in 0..<22 {
                let dash = slab(width: 0.18, height: 0.05, length: 1.5, color: .lanePaint, chamfer: 0)
                dash.position = SCNVector3(laneX(lane) - Self.laneSpacing / 2, 0.04, CGFloat(index) * -4.2)
                roadRoot.addChildNode(dash)
                laneDashNodes.append(dash)
            }
        }

        // Curbs hugging the road edge.
        for side in [-1.0, 1.0] {
            let curb = slab(width: 0.55, height: 0.3, length: 94, color: .shoulder, chamfer: 0.02)
            curb.position = SCNVector3((halfRoad + 0.25) * side, -0.02, -38)
            roadRoot.addChildNode(curb)

            let edgeLine = slab(width: 0.12, height: 0.06, length: 94, color: .edgePaint, chamfer: 0)
            edgeLine.position = SCNVector3((halfRoad - 0.28) * side, 0.045, -38)
            roadRoot.addChildNode(edgeLine)

            let rail = slab(width: 0.18, height: 0.18, length: 94, color: .guardRail, chamfer: 0.02)
            rail.position = SCNVector3((halfRoad + 0.78) * side, 0.48, -38)
            roadRoot.addChildNode(rail)
        }

        let grass = slab(width: 160, height: 0.12, length: 360, color: .grass, chamfer: 0)
        grass.position = SCNVector3(0, -0.22, -120)
        grass.name = "grass"
        world.addChildNode(grass)
        grass.renderingOrder = -10

        let grassFront = slab(width: 160, height: 0.12, length: 90, color: .grass, chamfer: 0)
        grassFront.position = SCNVector3(0, -0.22, 34)
        world.addChildNode(grassFront)
        grassFront.renderingOrder = -10
    }

    private func buildScenery() {
        for index in 0..<34 {
            let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
            let z = -CGFloat(index) * 3.4 - 3
            // Hug the road edge so the chunky trees/rocks peek into the grass margin
            // rather than sitting fully off-screen.
            let x = side * CGFloat.random(in: 6.6...9.5)
            let node = index.isMultiple(of: 3) ? buildRock() : buildTree()
            node.position = SCNVector3(x, 0, z)
            node.eulerAngles.y = SCNFloat(CGFloat.random(in: 0...CGFloat.pi))
            sceneryRoot.addChildNode(node)
            sceneryNodes.append(node)
        }
    }

    private func buildPlayer() {
        let style = model.selectedCarStyle
        playerNode.childNodes.forEach { $0.removeFromParentNode() }
        playerNode.addChildNode(buildCar(body: .hex(style.bodyHex), roof: .hex(style.roofHex), isPlayer: true))
        playerNode.scale = SCNVector3(Self.playerScale, Self.playerScale, Self.playerScale)
        playerNode.position = SCNVector3(0, 0.42, Self.playerZ)
        playerNode.eulerAngles.y = 0
        renderedPlayerCarIndex = model.selectedCarIndex
    }

    private func buildObstacles() {
        for _ in 0..<model.maxObstacles {
            let node = buildCar(body: .hex(model.obstacleColorHex(for: Int.random(in: 0..<6))), roof: .charcoal, isPlayer: false)
            node.isHidden = true
            obstacleRoot.addChildNode(node)
            obstacleNodes.append(node)
        }
    }
    
    private func buildCoins() {
        for _ in 0..<model.maxCoins {
            let coin = SCNCylinder(radius: 0.46, height: 0.16)
            let mat = material(.hex(0xFFD700))
            mat.metalness.contents = 0.9
            mat.roughness.contents = 0.2
            mat.emission.contents = PlatformColor.hex(0xFFC400)
            mat.emission.intensity = 0.9 // bright enough to catch the bloom pass
            coin.firstMaterial = mat
            let node = SCNNode(geometry: coin)
            node.eulerAngles.x = SCNFloat.pi / 2
            node.isHidden = true
            node.castsShadow = false
            coinRoot.addChildNode(node)
            coinNodes.append(node)
        }
    }

    private func updateWorld(time: TimeInterval) {
        let scroll = model.roadScroll / 18
        for (index, segment) in roadSegments.enumerated() {
            segment.position.z = SCNFloat(wrapZ(-CGFloat(index) * 5.2 + scroll.truncatingRemainder(dividingBy: 5.2), spacing: 18 * 5.2, near: 16))
        }
        for (index, dash) in laneDashNodes.enumerated() {
            dash.position.z = SCNFloat(wrapZ(-CGFloat(index % 22) * 4.2 + scroll.truncatingRemainder(dividingBy: 4.2), spacing: 22 * 4.2, near: 16))
        }
        for (index, node) in sceneryNodes.enumerated() {
            let base = -CGFloat(index) * 3.4 - 3
            node.position.z = SCNFloat(wrapZ(base + scroll.truncatingRemainder(dividingBy: 3.4), spacing: 34 * 3.4))
        }

        updatePlayer(time: time)
        updateObstacles()
        updateCoins()
        updateDebris()
        updateCamera(time: time)
    }

    private func updatePlayer(time: TimeInterval) {
        let style = model.selectedCarStyle
        if renderedPlayerCarIndex != model.selectedCarIndex || playerNode.childNodes.isEmpty {
            buildPlayer()
        } else if let car = playerNode.childNodes.first {
            applyCarColors(car, body: .hex(style.bodyHex), roof: .hex(style.roofHex), isPlayer: true)
        }

        let laneProgress = model.phase == .menu ? 0 : (model.carX - model.laneCenter(2)) / model.laneWidth
        let targetX = laneProgress * Self.laneSpacing
        let currentX = CGFloat(playerNode.position.x)
        playerNode.position.x = SCNFloat(currentX + (targetX - currentX) * 0.38)
        playerNode.position.y = SCNFloat(0.42 + sin(CGFloat(time) * (model.phase == .menu ? 3.2 : 16)) * (model.phase == .playing ? 0.045 : 0.025))
        if model.phase == .menu {
            playerNode.eulerAngles.y = SCNFloat(sin(CGFloat(time) * 0.9) * 0.28)
            playerNode.eulerAngles.z = SCNFloat(sin(CGFloat(time) * 1.4) * 0.035)
            playerNode.eulerAngles.x = 0
        } else {
            playerNode.eulerAngles.y = 0
            playerNode.eulerAngles.z = SCNFloat((targetX - currentX) * -0.08)
            playerNode.eulerAngles.x = SCNFloat(model.phase == .crash ? model.crashProgress(now: time) * 0.65 : 0)
        }
    }

    private func updateObstacles() {
        for index in obstacleNodes.indices {
            guard index < model.obstacles.count, model.obstacles[index].active else {
                obstacleNodes[index].isHidden = true
                obstacleNodes[index].opacity = 0
                continue
            }
            let obstacle = model.obstacles[index]
            let node = obstacleNodes[index]
            node.isHidden = false
            node.opacity = spawnOpacity(for: obstacle.y)
            node.position = SCNVector3(laneX(model.clampedLane(obstacle.lane)), 0.42, zForLogicY(obstacle.y))
            applyCarColors(node, body: .hex(model.obstacleColorHex(for: obstacle.type)), roof: .charcoal, isPlayer: false)
        }
    }
    
    private func updateCoins() {
        for index in coinNodes.indices {
            guard index < model.coins.count, model.coins[index].active else {
                coinNodes[index].isHidden = true
                coinNodes[index].opacity = 0
                continue
            }
            let coin = model.coins[index]
            let node = coinNodes[index]
            node.isHidden = false
            node.opacity = spawnOpacity(for: coin.y)
            node.position = SCNVector3(laneX(model.clampedLane(coin.lane)), 0.5 + sin(coin.rot) * 0.1, zForLogicY(coin.y))
            node.eulerAngles.y = SCNFloat(coin.rot)
        }
    }

    private func updateDebris() {
        while debrisNodes.count < model.debris.count {
            let node = slab(width: 0.16, height: 0.16, length: 0.16, color: .coral, chamfer: 0.02)
            debrisRoot.addChildNode(node)
            debrisNodes.append(node)
        }
        for index in debrisNodes.indices {
            guard index < model.debris.count, model.debris[index].active else {
                debrisNodes[index].isHidden = true
                continue
            }
            let debris = model.debris[index]
            debrisNodes[index].isHidden = false
            debrisNodes[index].position = SCNVector3(
                (debris.position.x - 150) / 25, // Adjusted for new logicSize width (300/2 = 150)
                0.8 + debris.size / 10,
                zForLogicY(debris.position.y)
            )
            debrisNodes[index].geometry?.firstMaterial?.diffuse.contents = PlatformColor.hex(debris.colorHex)
        }
    }

    private func updateCamera(time: TimeInterval) {
        let shake = model.phase == .crash ? model.cameraShake / 40 : .zero
        let speedT = min(model.speed / 320, 1.4)
        let profile = cameraProfile
        let menuLift: CGFloat = model.phase == .menu ? -0.42 : 0
        let menuBack: CGFloat = model.phase == .menu ? -0.85 : 0
        let desired = SCNVector3(
            SCNFloat(shake.dx),
            SCNFloat(profile.height + speedT * profile.speedLift + menuLift),
            SCNFloat(Self.playerZ + profile.back + speedT * profile.speedBack + shake.dy + menuBack)
        )
        cameraNode.camera?.fieldOfView += (profile.fov - (cameraNode.camera?.fieldOfView ?? profile.fov)) * 0.08
        cameraNode.eulerAngles.x += (SCNFloat(profile.pitch) - cameraNode.eulerAngles.x) * 0.08
        scene.fogStartDistance += (profile.fogStart - scene.fogStartDistance) * 0.08
        scene.fogEndDistance += (profile.fogEnd - scene.fogEndDistance) * 0.08
        cameraNode.position.x += (desired.x - cameraNode.position.x) * 0.14
        cameraNode.position.y += (desired.y - cameraNode.position.y) * 0.14
        cameraNode.position.z += (desired.z - cameraNode.position.z) * 0.14
    }

    private func updateHUD() {
        let style = model.selectedCarStyle
        let snapshot = HUDSnapshot(
            score: model.score,
            highScore: model.highScore,
            coins: model.coinsCollected,
            speed: Int(model.speed),
            distance: Int(model.distance),
            phase: model.phase,
            throttle: input.throttle,
            carName: style.name,
            carColorR: Double((style.bodyHex >> 16) & 0xFF) / 255.0,
            carColorG: Double((style.bodyHex >> 8) & 0xFF) / 255.0,
            carColorB: Double(style.bodyHex & 0xFF) / 255.0,
            carRoofR: Double((style.roofHex >> 16) & 0xFF) / 255.0,
            carRoofG: Double((style.roofHex >> 8) & 0xFF) / 255.0,
            carRoofB: Double(style.roofHex & 0xFF) / 255.0,
            selectedCarIndex: model.selectedCarIndex
        )
        guard snapshot != lastHUDSnapshot else { return }
        lastHUDSnapshot = snapshot

        let target = hudState
        Task { @MainActor in
            target.apply(snapshot)
        }
    }

    private func laneX(_ lane: Int) -> CGFloat {
        (CGFloat(model.clampedLane(lane)) - 2) * Self.laneSpacing
    }

    /// Map logic-space Y (collision space) to world Z. The player's collision row
    /// (`model.carY`) maps exactly onto the player node, so a crash happens right
    /// where the cars visually overlap instead of after the obstacle slides past.
    private func zForLogicY(_ y: CGFloat) -> CGFloat {
        Self.playerZ - (model.carY - y) * Self.zPerLogic
    }

    private func spawnOpacity(for y: CGFloat) -> CGFloat {
        let fadeDistance: CGFloat = 96
        let progress = (y - model.spawnY) / fadeDistance
        return min(max(progress, 0), 1)
    }

    private func wrapZ(_ z: CGFloat, spacing: CGFloat, near: CGFloat = 8) -> CGFloat {
        var value = z
        while value > near { value -= spacing }
        while value < near - spacing { value += spacing }
        return value
    }
}

#if os(macOS)
final class GameSCNView: SCNView {
    weak var gameInputHandler: GameInputHandling?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 49, 36:
            if !event.isARepeat { gameInputHandler?.pressStart() }
        case 0, 123:
            if !event.isARepeat { gameInputHandler?.swipeLane(-1) }
        case 2, 124:
            if !event.isARepeat { gameInputHandler?.swipeLane(1) }
        case 13, 126:
            gameInputHandler?.setThrottle(100)
        case 1, 125:
            gameInputHandler?.setThrottle(-100)
        case 46:
            if !event.isARepeat { gameInputHandler?.pressMenu() }
        default: break
        }
    }

    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 1, 13, 125, 126: gameInputHandler?.setThrottle(0)
        default: break
        }
    }
}
#else
final class GameSCNView: SCNView {
    weak var gameInputHandler: GameInputHandling?

    private var touchStart = CGPoint.zero
    private var laneAnchorX: CGFloat = 0
    private var travelled: CGFloat = 0
    private let laneThreshold: CGFloat = 22
    private let tapTolerance: CGFloat = 12

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchStart = point
        laneAnchorX = point.x
        travelled = 0
        gameInputHandler?.touchDown()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        let dx = point.x - laneAnchorX
        if dx > laneThreshold {
            gameInputHandler?.swipeLane(1)
            laneAnchorX = point.x
        } else if dx < -laneThreshold {
            gameInputHandler?.swipeLane(-1)
            laneAnchorX = point.x
        }

        let dy = point.y - touchStart.y
        gameInputHandler?.dragThrottle(dy)

        travelled = max(travelled, hypot(point.x - touchStart.x, point.y - touchStart.y))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if travelled < tapTolerance {
            gameInputHandler?.tap()
        }
        gameInputHandler?.touchUp()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameInputHandler?.touchUp()
    }
}
#endif

private func slab(width: CGFloat, height: CGFloat, length: CGFloat, color: PlatformColor, chamfer: CGFloat) -> SCNNode {
    let box = SCNBox(width: width, height: height, length: length, chamferRadius: chamfer)
    box.firstMaterial = material(color)
    let node = SCNNode(geometry: box)
    node.castsShadow = true
    return node
}

private func material(_ color: PlatformColor) -> SCNMaterial {
    let mat = SCNMaterial()
    mat.diffuse.contents = color
    mat.lightingModel = .physicallyBased
    mat.roughness.contents = 0.92
    mat.metalness.contents = 0.02
    mat.locksAmbientWithDiffuse = true
    return mat
}

private func buildCar(body: PlatformColor, roof: PlatformColor, isPlayer: Bool) -> SCNNode {
    // Chunky, almost voxel proportions: a fat lower body, a stubby raised cabin,
    // thick wheels and bold lights. Hard chamfers keep the blocky read.
    let root = SCNNode()

    let base = slab(width: 1.34, height: 0.48, length: 1.96, color: body, chamfer: 0.04)
    base.name = "body"
    base.position.y = 0.25
    root.addChildNode(base)

    let hood = slab(width: 1.18, height: 0.12, length: 0.62, color: body.blended(with: .white, amount: 0.10), chamfer: 0.025)
    hood.name = "body"
    hood.position = SCNVector3(0, 0.55, isPlayer ? -0.52 : 0.52)
    root.addChildNode(hood)

    // A dark trim band around the midline (bumper). Fixed colour so it stays
    // correct when the car is recoloured (only "body"/"roof" nodes recolour).
    let trim = slab(width: 1.4, height: 0.12, length: 2.02, color: .charcoal, chamfer: 0.035)
    trim.position.y = 0.5
    root.addChildNode(trim)

    let frontBumper = slab(width: 1.18, height: 0.18, length: 0.16, color: .bumper, chamfer: 0.025)
    frontBumper.position = SCNVector3(0, 0.27, isPlayer ? -1.04 : 1.04)
    root.addChildNode(frontBumper)

    let rearBumper = slab(width: 1.12, height: 0.16, length: 0.14, color: .bumper, chamfer: 0.025)
    rearBumper.position = SCNVector3(0, 0.27, isPlayer ? 1.04 : -1.04)
    root.addChildNode(rearBumper)

    let cabin = slab(width: 0.92, height: 0.58, length: 0.92, color: roof, chamfer: 0.04)
    cabin.name = "roof"
    cabin.position = SCNVector3(0, 0.86, isPlayer ? -0.1 : 0.1)
    root.addChildNode(cabin)

    // Windshield strip for a bit of character.
    let glass = slab(width: 0.8, height: 0.34, length: 0.1, color: .glass, chamfer: 0.02)
    glass.position = SCNVector3(0, 0.86, isPlayer ? -0.6 : 0.6)
    root.addChildNode(glass)

    for x in [-0.49, 0.49] {
        let sideGlass = slab(width: 0.08, height: 0.28, length: 0.52, color: .glassDark, chamfer: 0.01)
        sideGlass.position = SCNVector3(x, 0.86, 0)
        root.addChildNode(sideGlass)
    }

    let grille = slab(width: 0.62, height: 0.16, length: 0.05, color: .grille, chamfer: 0.01)
    grille.position = SCNVector3(0, 0.38, isPlayer ? -1.08 : 1.08)
    root.addChildNode(grille)

    let spoiler = slab(width: 1.0, height: 0.08, length: 0.16, color: roof, chamfer: 0.02)
    spoiler.name = "roof"
    spoiler.position = SCNVector3(0, 0.78, isPlayer ? 0.96 : -0.96)
    root.addChildNode(spoiler)

    for x in [-0.56, 0.56] {
        for z in [-0.62, 0.62] {
            let wheel = SCNCylinder(radius: 0.28, height: 0.26)
            wheel.firstMaterial = material(.tire)
            let node = SCNNode(geometry: wheel)
            node.name = "wheel"
            node.eulerAngles.z = SCNFloat.pi / 2
            node.position = SCNVector3(x, 0.19, z)
            root.addChildNode(node)

            let hub = SCNCylinder(radius: 0.13, height: 0.28)
            hub.firstMaterial = material(.hubcap)
            let hubNode = SCNNode(geometry: hub)
            hubNode.eulerAngles.z = SCNFloat.pi / 2
            hubNode.position = node.position
            root.addChildNode(hubNode)
        }
    }

    let lightColor: PlatformColor = isPlayer ? .headlight : .tailLight
    let names = isPlayer ? ["headlightL", "headlightR"] : ["taillightL", "taillightR"]
    for (i, x) in [-0.36, 0.36].enumerated() {
        let light = slab(width: 0.24, height: 0.12, length: 0.06, color: lightColor, chamfer: 0.01)
        light.name = names[i]
        light.geometry?.firstMaterial?.emission.contents = lightColor
        light.geometry?.firstMaterial?.emission.intensity = isPlayer ? 0.4 : 0.8
        light.position = SCNVector3(x, 0.4, isPlayer ? -0.98 : 0.98)
        root.addChildNode(light)
    }

    let otherLightColor: PlatformColor = isPlayer ? .tailLight : .headlight
    let otherNames = isPlayer ? ["taillightL", "taillightR"] : ["headlightL", "headlightR"]
    for (i, x) in [-0.36, 0.36].enumerated() {
        let light = slab(width: 0.24, height: 0.12, length: 0.06, color: otherLightColor, chamfer: 0.01)
        light.name = otherNames[i]
        light.geometry?.firstMaterial?.emission.contents = otherLightColor
        light.geometry?.firstMaterial?.emission.intensity = isPlayer ? 0.8 : 0.4
        light.position = SCNVector3(x, 0.4, isPlayer ? 0.98 : -0.98)
        root.addChildNode(light)
    }

    return root
}

private func applyCarColors(_ node: SCNNode, body: PlatformColor, roof: PlatformColor, isPlayer: Bool) {
    node.enumerateChildNodes { child, _ in
        if child.name == "body" {
            child.geometry?.firstMaterial?.diffuse.contents = body
        } else if child.name == "roof" {
            child.geometry?.firstMaterial?.diffuse.contents = roof
        }
    }

    let headlightIntensity = isPlayer ? 0.55 : 0.28
    let taillightIntensity = isPlayer ? 0.85 : 0.55
    for name in ["headlightL", "headlightR"] {
        let mat = node.childNode(withName: name, recursively: true)?.geometry?.firstMaterial
        mat?.diffuse.contents = PlatformColor.headlight
        mat?.emission.contents = PlatformColor.headlight
        mat?.emission.intensity = headlightIntensity
    }
    for name in ["taillightL", "taillightR"] {
        let mat = node.childNode(withName: name, recursively: true)?.geometry?.firstMaterial
        mat?.diffuse.contents = PlatformColor.tailLight
        mat?.emission.contents = PlatformColor.tailLight
        mat?.emission.intensity = taillightIntensity
    }
}

private func buildTree() -> SCNNode {
    // Voxel-style tree: a block trunk topped by two stacked foliage cubes.
    // NOTE: position.y is `Float` on iOS (SCNFloat) / `CGFloat` on macOS, so every
    // CGFloat height must be wrapped in `SCNFloat(...)` before assigning.
    let root = SCNNode()

    let trunkHeight: CGFloat = 1.0
    let trunk = slab(width: 0.4, height: trunkHeight, length: 0.4, color: .trunk, chamfer: 0.02)
    trunk.position.y = SCNFloat(trunkHeight / 2)
    root.addChildNode(trunk)

    let lowerSize = CGFloat.random(in: 1.5...1.9)
    let lowerHeight = lowerSize * 0.7
    let lower = slab(width: lowerSize, height: lowerHeight, length: lowerSize, color: .tree, chamfer: 0.05)
    lower.position.y = SCNFloat(trunkHeight + lowerHeight / 2)
    lower.eulerAngles.y = SCNFloat(CGFloat.random(in: -0.3...0.3))
    root.addChildNode(lower)

    let upperSize = lowerSize * 0.62
    let upperY = trunkHeight + lowerHeight + upperSize / 2 - 0.1
    let upper = slab(width: upperSize, height: upperSize, length: upperSize, color: .treeLight, chamfer: 0.05)
    upper.position.y = SCNFloat(upperY)
    upper.eulerAngles.y = SCNFloat(CGFloat.random(in: -0.4...0.4))
    root.addChildNode(upper)

    return root
}

private func buildBush() -> SCNNode {
    let root = SCNNode()
    let size = CGFloat.random(in: 0.9...1.3)
    let main = slab(width: size, height: size * 0.8, length: size, color: .tree, chamfer: 0.06)
    main.position.y = SCNFloat(size * 0.4)
    main.eulerAngles.y = SCNFloat(CGFloat.random(in: 0...CGFloat.pi))
    root.addChildNode(main)
    let cap = slab(width: size * 0.6, height: size * 0.5, length: size * 0.6, color: .treeLight, chamfer: 0.06)
    cap.position = SCNVector3(SCNFloat(size * 0.2), SCNFloat(size * 0.75), 0)
    root.addChildNode(cap)
    return root
}

private func buildStreetlight() -> SCNNode {
    let root = SCNNode()
    let pole = slab(width: 0.16, height: 3.4, length: 0.16, color: .charcoal, chamfer: 0.02)
    pole.position.y = 1.7
    root.addChildNode(pole)
    let arm = slab(width: 0.16, height: 0.16, length: 1.0, color: .charcoal, chamfer: 0.02)
    arm.position = SCNVector3(0, 3.35, -0.45)
    root.addChildNode(arm)
    let lamp = slab(width: 0.34, height: 0.16, length: 0.5, color: .headlight, chamfer: 0.03)
    lamp.geometry?.firstMaterial?.emission.contents = PlatformColor.headlight
    lamp.geometry?.firstMaterial?.emission.intensity = 0.55
    lamp.position = SCNVector3(0, 3.2, -0.9)
    root.addChildNode(lamp)
    return root
}

private func buildRock() -> SCNNode {
    let root = SCNNode()
    let rock = slab(width: CGFloat.random(in: 0.7...1.3), height: CGFloat.random(in: 0.5...0.95), length: CGFloat.random(in: 0.7...1.4), color: .rock, chamfer: 0.06)
    rock.position.y = 0.2
    rock.eulerAngles.y = SCNFloat(CGFloat.random(in: 0...CGFloat.pi))
    root.addChildNode(rock)
    // A smaller block leaning against it for a clustered, chunky silhouette.
    let chip = slab(width: 0.5, height: 0.4, length: 0.5, color: .rock, chamfer: 0.05)
    chip.position = SCNVector3(CGFloat.random(in: -0.5...0.5), 0.14, CGFloat.random(in: -0.4...0.4))
    chip.eulerAngles.y = SCNFloat(CGFloat.random(in: 0...CGFloat.pi))
    root.addChildNode(chip)
    return root
}

#if os(iOS)
@MainActor
enum GameHaptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .rigid)
    private static let notify = UINotificationFeedbackGenerator()

    static func laneChange() {
        light.prepare()
        light.impactOccurred(intensity: 0.55)
    }

    static func coin() {
        medium.prepare()
        medium.impactOccurred(intensity: 0.85)
    }

    static func crash() {
        notify.prepare()
        notify.notificationOccurred(.error)
        heavy.prepare()
        heavy.impactOccurred(intensity: 1.0)
    }
}
#endif

private extension CGVector {
    static func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

private extension PlatformColor {
    static var sky: PlatformColor { PlatformColor(red: 0.42, green: 0.74, blue: 0.95, alpha: 1) }
    static var road: PlatformColor { PlatformColor(red: 0.27, green: 0.29, blue: 0.33, alpha: 1) }
    static var shoulder: PlatformColor { PlatformColor(red: 0.86, green: 0.88, blue: 0.90, alpha: 1) }
    static var lanePaint: PlatformColor { PlatformColor(red: 0.98, green: 0.94, blue: 0.70, alpha: 1) }
    static var edgePaint: PlatformColor { PlatformColor(red: 0.92, green: 0.95, blue: 0.96, alpha: 1) }
    static var guardRail: PlatformColor { PlatformColor(red: 0.80, green: 0.84, blue: 0.87, alpha: 1) }
    static var grass: PlatformColor { PlatformColor(red: 0.36, green: 0.74, blue: 0.40, alpha: 1) }
    static var tree: PlatformColor { PlatformColor(red: 0.20, green: 0.60, blue: 0.33, alpha: 1) }
    static var treeLight: PlatformColor { PlatformColor(red: 0.36, green: 0.76, blue: 0.42, alpha: 1) }
    static var trunk: PlatformColor { PlatformColor(red: 0.52, green: 0.34, blue: 0.18, alpha: 1) }
    static var rock: PlatformColor { PlatformColor(red: 0.62, green: 0.66, blue: 0.69, alpha: 1) }
    static var tire: PlatformColor { PlatformColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1) }
    static var hubcap: PlatformColor { PlatformColor(red: 0.77, green: 0.80, blue: 0.82, alpha: 1) }
    static var glass: PlatformColor { PlatformColor(red: 0.55, green: 0.78, blue: 0.92, alpha: 1) }
    static var glassDark: PlatformColor { PlatformColor(red: 0.18, green: 0.33, blue: 0.46, alpha: 1) }
    static var charcoal: PlatformColor { PlatformColor(red: 0.12, green: 0.13, blue: 0.15, alpha: 1) }
    static var bumper: PlatformColor { PlatformColor(red: 0.07, green: 0.08, blue: 0.09, alpha: 1) }
    static var grille: PlatformColor { PlatformColor(red: 0.03, green: 0.035, blue: 0.04, alpha: 1) }
    static var headlight: PlatformColor { PlatformColor(red: 1.0, green: 0.96, blue: 0.62, alpha: 1) }
    static var tailLight: PlatformColor { PlatformColor(red: 1.0, green: 0.18, blue: 0.16, alpha: 1) }
    static var coral: PlatformColor { PlatformColor(red: 1.0, green: 0.25, blue: 0.18, alpha: 1) }
    static var mint: PlatformColor { PlatformColor(red: 0.48, green: 1.0, blue: 0.66, alpha: 1) }

    static func hex(_ hex: UInt32) -> PlatformColor {
        PlatformColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
    
    func blended(with color: PlatformColor, amount: CGFloat) -> PlatformColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        #if os(macOS)
        self.usingColorSpace(.deviceRGB)?.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.usingColorSpace(.deviceRGB)?.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        #else
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        #endif
        
        let t = min(max(amount, 0), 1)
        return PlatformColor(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, alpha: a1 + (a2 - a1) * t)
    }
}
