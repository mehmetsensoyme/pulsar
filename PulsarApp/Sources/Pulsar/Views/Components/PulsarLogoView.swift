import SwiftUI
import AppKit

public struct PulsarLogoView: View {
    public let size: CGFloat
    public let showShadow: Bool

    public init(size: CGFloat = 48, showShadow: Bool = true) {
        self.size = size
        self.showShadow = showShadow
    }

    private var loadedImage: NSImage? {
        // 1. Try to load from bundle Resources
        if let bundlePath = Bundle.main.path(forResource: "logo", ofType: "png"),
           let img = NSImage(contentsOfFile: bundlePath) {
            return img
        }
        // 2. Try AppIcon from app bundle
        if let icon = NSApplication.shared.applicationIconImage {
            return icon
        }
        return nil
    }

    public var body: some View {
        ZStack {
            if let nsImg = loadedImage {
                Image(nsImage: nsImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                // High-fidelity native SwiftUI vector rendering of Pulsar Logo
                vectorPulsarLogo
                    .frame(width: size, height: size)
            }
        }
        .shadow(color: showShadow ? Color.cyan.opacity(0.3) : Color.clear, radius: size * 0.1, x: 0, y: size * 0.04)
    }

    private var vectorPulsarLogo: some View {
        ZStack {
            // Squircle Arka Plan
            RoundedRectangle(cornerRadius: size * 0.224)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.06, blue: 0.11),
                            Color(red: 0.12, green: 0.07, blue: 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.224)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.cyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1, size * 0.02)
                        )
                )

            // Geometrik Veri Kapsülü (Hexagon)
            HexagonShape()
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.8), Color.purple.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: max(1, size * 0.025)
                )
                .frame(width: size * 0.62, height: size * 0.62)

            // Çapraz Enerji Jetleri (Particle Beams)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.cyan, Color.white, Color.purple, Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.75, height: max(2, size * 0.04))
                .rotationEffect(.degrees(-35))

            // Dönen Halka (Accretion Disk)
            Ellipse()
                .stroke(
                    AngularGradient(
                        colors: [Color.cyan, Color.purple, Color.cyan],
                        center: .center
                    ),
                    lineWidth: max(1.5, size * 0.035)
                )
                .frame(width: size * 0.52, height: size * 0.24)
                .rotationEffect(.degrees(22))

            // Parlayan Pulsar Çekirdeği
            Circle()
                .fill(Color.cyan.opacity(0.6))
                .frame(width: size * 0.28, height: size * 0.28)
                .blur(radius: max(1, size * 0.06))

            Circle()
                .fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.12)
        }
    }
}

private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let angle = CGFloat(i) * (.pi / 3) + (.pi / 6)
            let x = cx + r * cos(angle)
            let y = cy + r * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
