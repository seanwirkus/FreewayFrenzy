import SwiftUI

struct IsoCarView: View {
    var type: CarBodyType = .sedan
    var color: Color
    var scale: CGFloat = 1

    private var config: IsoCarConfig {
        switch type {
        case .sedan: return IsoCarConfig(width: 150, height: 110, originX: 65, originY: 50)
        case .sports: return IsoCarConfig(width: 150, height: 100, originX: 65, originY: 52)
        case .suv: return IsoCarConfig(width: 150, height: 125, originX: 65, originY: 60)
        case .truck: return IsoCarConfig(width: 175, height: 130, originX: 55, originY: 60)
        }
    }

    var body: some View {
        Canvas { context, size in
            let drawer = IsoCarDrawer(context: context, color: color, originX: config.originX, originY: config.originY)
            switch type {
            case .sedan: drawer.drawSedan()
            case .sports: drawer.drawSports()
            case .suv: drawer.drawSUV()
            case .truck: drawer.drawTruck()
            }
        }
        .frame(width: config.width * scale, height: config.height * scale)
        .drawingGroup()
    }
}

private struct IsoCarConfig {
    let width: CGFloat
    let height: CGFloat
    let originX: CGFloat
    let originY: CGFloat
}

private struct IsoCarDrawer {
    let context: GraphicsContext
    let baseColor: Color
    let originX: CGFloat
    let originY: CGFloat

    private static let sx: CGFloat = 10
    private static let sy: CGFloat = 5
    private static let sz: CGFloat = 13

    init(context: GraphicsContext, color: Color, originX: CGFloat, originY: CGFloat) {
        self.context = context
        self.baseColor = color
        self.originX = originX
        self.originY = originY
    }

    private func project(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> CGPoint {
        CGPoint(
            x: originX + (x - y) * Self.sx,
            y: originY + (x + y) * Self.sy - z * Self.sz
        )
    }

    private func face(_ corners: [(CGFloat, CGFloat, CGFloat)]) -> Path {
        var path = Path()
        guard let first = corners.first else { return path }
        path.move(to: project(first.0, first.1, first.2))
        for corner in corners.dropFirst() {
            path.addLine(to: project(corner.0, corner.1, corner.2))
        }
        path.closeSubpath()
        return path
    }

    private func shade(_ factor: CGFloat) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        #if os(macOS)
        NSColor(baseColor).usingColorSpace(.deviceRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        UIColor(baseColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        return Color(red: Double(r * factor), green: Double(g * factor), blue: Double(b * factor), opacity: Double(a))
    }

    private func lighten(_ amount: CGFloat) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        #if os(macOS)
        NSColor(baseColor).usingColorSpace(.deviceRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        UIColor(baseColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        return Color(
            red: Double(min(r + amount / 255, 1)),
            green: Double(min(g + amount / 255, 1)),
            blue: Double(min(b + amount / 255, 1)),
            opacity: Double(a)
        )
    }

    private func drawCube(x: CGFloat, y: CGFloat, z: CGFloat, dx: CGFloat, dy: CGFloat, dz: CGFloat, color: Color? = nil) {
        let left = shade(0.78)
        let right = shade(0.58)
        let top = lighten(18)

        context.fill(face([(x, y, z), (x + dx, y, z), (x + dx, y, z + dz), (x, y, z + dz)]), with: .color(left))
        context.stroke(face([(x, y, z), (x + dx, y, z), (x + dx, y, z + dz), (x, y, z + dz)]), with: .color(.black.opacity(0.35)), lineWidth: 0.6)

        context.fill(face([(x + dx, y, z), (x + dx, y + dy, z), (x + dx, y + dy, z + dz), (x + dx, y, z + dz)]), with: .color(right))
        context.stroke(face([(x + dx, y, z), (x + dx, y + dy, z), (x + dx, y + dy, z + dz), (x + dx, y, z + dz)]), with: .color(.black.opacity(0.35)), lineWidth: 0.6)

        context.fill(face([(x, y, z + dz), (x + dx, y, z + dz), (x + dx, y + dy, z + dz), (x, y + dy, z + dz)]), with: .color(top))
        context.stroke(face([(x, y, z + dz), (x + dx, y, z + dz), (x + dx, y + dy, z + dz), (x, y + dy, z + dz)]), with: .color(.black.opacity(0.35)), lineWidth: 0.6)
    }

    private func drawShadow(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat) {
        context.fill(face([(x, y, 0), (x + dx, y, 0), (x + dx, y + dy, 0), (x, y + dy, 0)]), with: .color(.black.opacity(0.22)))
    }

    private func drawWheel(x: CGFloat, y: CGFloat, h: CGFloat = 0.5) {
        drawCube(x: x, y: y, z: 0, dx: 0.7, dy: 0.6, dz: h, color: Color(red: 0.10, green: 0.07, blue: 0.03))
    }

    private func drawWindow(_ corners: [(CGFloat, CGFloat, CGFloat)]) {
        context.fill(face(corners), with: .color(Color(red: 0.43, green: 0.78, blue: 1.0, opacity: 0.55)))
        context.stroke(face(corners), with: .color(.black.opacity(0.4)), lineWidth: 0.5)
    }

    private func drawHeadlight(_ corners: [(CGFloat, CGFloat, CGFloat)]) {
        context.fill(face(corners), with: .color(Color(red: 1.0, green: 0.96, blue: 0.70)))
    }

    func drawSedan() {
        drawShadow(x: -0.3, y: -0.3, dx: 5.6, dy: 3.6)
        drawWheel(x: 0.2, y: -0.05)
        drawWheel(x: 0.2, y: 2.45)
        drawWheel(x: 4.0, y: -0.05)
        drawWheel(x: 4.0, y: 2.45)
        drawCube(x: 0, y: 0, z: 0.4, dx: 5, dy: 3, dz: 0.7)
        drawCube(x: 1.1, y: 0.3, z: 1.1, dx: 2.8, dy: 2.4, dz: 0.9)
        drawWindow([(1.35, 0.3, 1.3), (3.65, 0.3, 1.3), (3.65, 0.3, 1.92), (1.35, 0.3, 1.92)])
        drawWindow([(3.9, 0.5, 1.3), (3.9, 2.5, 1.3), (3.9, 2.5, 1.92), (3.9, 0.5, 1.92)])
        drawHeadlight([(5.01, 0.25, 0.55), (5.01, 0.85, 0.55), (5.01, 0.85, 0.95), (5.01, 0.25, 0.95)])
        drawHeadlight([(5.01, 2.15, 0.55), (5.01, 2.75, 0.55), (5.01, 2.75, 0.95), (5.01, 2.15, 0.95)])
    }

    func drawSports() {
        drawShadow(x: -0.3, y: -0.3, dx: 5.6, dy: 3.6)
        drawWheel(x: 0.3, y: -0.05, h: 0.55)
        drawWheel(x: 0.3, y: 2.45, h: 0.55)
        drawWheel(x: 4.1, y: -0.05, h: 0.55)
        drawWheel(x: 4.1, y: 2.45, h: 0.55)
        drawCube(x: 0, y: 0, z: 0.45, dx: 5, dy: 3, dz: 0.5)
        drawCube(x: 3.9, y: 0, z: 0.95, dx: 1.1, dy: 3, dz: 0.2)
        drawCube(x: 1.4, y: 0.35, z: 0.95, dx: 2.5, dy: 2.3, dz: 0.55)
        drawWindow([(1.55, 0.35, 1.05), (3.85, 0.35, 1.05), (3.85, 0.35, 1.45), (1.55, 0.35, 1.45)])
        drawWindow([(3.9, 0.55, 1.05), (3.9, 2.45, 1.05), (3.9, 2.45, 1.45), (3.9, 0.55, 1.45)])
        drawCube(x: -0.1, y: 0.2, z: 0.95, dx: 0.25, dy: 2.6, dz: 0.4, color: shade(0.4))
        drawHeadlight([(5.01, 0.2, 0.55), (5.01, 0.9, 0.55), (5.01, 0.9, 0.9), (5.01, 0.2, 0.9)])
        drawHeadlight([(5.01, 2.1, 0.55), (5.01, 2.8, 0.55), (5.01, 2.8, 0.9), (5.01, 2.1, 0.9)])
        context.fill(face([(0, 1.3, 1.501), (5, 1.3, 1.501), (5, 1.7, 1.501), (0, 1.7, 1.501)]), with: .color(lighten(60)))
    }

    func drawSUV() {
        drawShadow(x: -0.3, y: -0.3, dx: 5.6, dy: 3.6)
        drawWheel(x: 0.2, y: -0.1, h: 0.6)
        drawWheel(x: 0.2, y: 2.5, h: 0.6)
        drawWheel(x: 4.0, y: -0.1, h: 0.6)
        drawWheel(x: 4.0, y: 2.5, h: 0.6)
        drawCube(x: 0, y: 0, z: 0.55, dx: 5, dy: 3, dz: 0.85)
        drawCube(x: 0.3, y: 0.2, z: 1.4, dx: 4.5, dy: 2.6, dz: 1.3)
        drawWindow([(0.55, 0.2, 1.65), (2.05, 0.2, 1.65), (2.05, 0.2, 2.5), (0.55, 0.2, 2.5)])
        drawWindow([(2.4, 0.2, 1.65), (4.45, 0.2, 1.65), (4.45, 0.2, 2.5), (2.4, 0.2, 2.5)])
        context.fill(face([(2.05, 0.2, 1.65), (2.4, 0.2, 1.65), (2.4, 0.2, 2.5), (2.05, 0.2, 2.5)]), with: .color(shade(0.45)))
        drawWindow([(4.81, 0.45, 1.65), (4.81, 2.55, 1.65), (4.81, 2.55, 2.5), (4.81, 0.45, 2.5)])
        drawCube(x: 0.9, y: 0.3, z: 2.7, dx: 3.3, dy: 2.4, dz: 0.1, color: shade(0.4))
        drawHeadlight([(5.01, 0.15, 0.7), (5.01, 0.9, 0.7), (5.01, 0.9, 1.15), (5.01, 0.15, 1.15)])
        drawHeadlight([(5.01, 2.1, 0.7), (5.01, 2.85, 0.7), (5.01, 2.85, 1.15), (5.01, 2.1, 1.15)])
    }

    func drawTruck() {
        drawShadow(x: -0.3, y: -0.3, dx: 6.6, dy: 3.6)
        for wx in [0.2, 3.0, 5.2] {
            drawWheel(x: wx, y: -0.05, h: 0.6)
            drawWheel(x: wx, y: 2.45, h: 0.6)
        }
        drawCube(x: 0, y: 0, z: 0.55, dx: 6, dy: 3, dz: 0.55)
        drawCube(x: 0, y: 0, z: 1.1, dx: 0.2, dy: 3, dz: 0.6, color: shade(0.55))
        drawCube(x: 0, y: 0, z: 1.1, dx: 4, dy: 0.2, dz: 0.6, color: shade(0.55))
        drawCube(x: 0, y: 2.8, z: 1.1, dx: 4, dy: 0.2, dz: 0.6, color: shade(0.55))
        drawCube(x: 3.8, y: 0, z: 1.1, dx: 0.2, dy: 3, dz: 0.6, color: shade(0.55))
        context.fill(face([(0.2, 0.2, 1.11), (3.8, 0.2, 1.11), (3.8, 2.8, 1.11), (0.2, 2.8, 1.11)]), with: .color(shade(0.35)))
        drawCube(x: 4, y: 0, z: 1.1, dx: 2, dy: 3, dz: 1.55)
        drawWindow([(4.2, 0, 1.3), (5.8, 0, 1.3), (5.8, 0, 2.45), (4.2, 0, 2.45)])
        drawWindow([(6.01, 0.3, 1.3), (6.01, 2.7, 1.3), (6.01, 2.7, 2.45), (6.01, 0.3, 2.45)])
        drawHeadlight([(6.01, 0.2, 1.2), (6.01, 0.95, 1.2), (6.01, 0.95, 1.5), (6.01, 0.2, 1.5)])
        drawHeadlight([(6.01, 2.05, 1.2), (6.01, 2.8, 1.2), (6.01, 2.8, 1.5), (6.01, 2.05, 1.5)])
        drawCube(x: 5.95, y: -0.05, z: 1.05, dx: 0.1, dy: 3.1, dz: 0.15, color: Color(red: 0.83, green: 0.75, blue: 0.54))
    }
}

#if os(macOS)
import AppKit
#else
import UIKit
#endif
