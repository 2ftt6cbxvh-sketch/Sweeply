import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var padding: CGFloat
    public var showsBorder: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(cornerRadius: CGFloat = 22, padding: CGFloat = 0, showsBorder: Bool = true) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.showsBorder = showsBorder
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    // 1. Ultra-thin material blur to sample ambient background colors
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // 2. Translucent glass tint with top-to-bottom specular gradient
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.10), Color.white.opacity(0.02), Color.clear]
                                    : [Color.white.opacity(0.70), Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    if showsBorder {
                        // 3. Crisp luminous glass highlight border
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: colorScheme == .dark ? Color.white.opacity(0.45) : Color.white, location: 0.0),
                                        .init(color: colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.50), location: 0.35),
                                        .init(color: Color.clear, location: 0.65),
                                        .init(color: colorScheme == .dark ? Color.cyan.opacity(0.3) : Color.blue.opacity(0.2), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                }
                // 4. Soft ambient depth shadow
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.5) : Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.10),
                    radius: 18,
                    x: 0,
                    y: 8
                )
            }
    }
}

public struct AmbientGlassBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Base background
            (colorScheme == .dark ? Color(red: 0.05, green: 0.07, blue: 0.12) : Color(red: 0.94, green: 0.96, blue: 0.99))
                .ignoresSafeArea()
            
            // Glowing Ambient Color Orbs that shine through frosted glass
            GeometryReader { geo in
                // Orb 1: Electric Blue (Top Left)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (colorScheme == .dark ? Color.blue.opacity(0.35) : Color.blue.opacity(0.22)),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 220
                        )
                    )
                    .frame(width: 440, height: 440)
                    .offset(x: -120, y: -100)
                    .blur(radius: 50)
                
                // Orb 2: Vivid Violet / Purple (Top Right)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (colorScheme == .dark ? Color.purple.opacity(0.30) : Color.purple.opacity(0.18)),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: geo.size.width - 240, y: 40)
                    .blur(radius: 55)
                
                // Orb 3: Cyan / Mint (Center / Bottom)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (colorScheme == .dark ? Color.cyan.opacity(0.25) : Color.teal.opacity(0.16)),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 250
                        )
                    )
                    .frame(width: 500, height: 500)
                    .offset(x: -80, y: geo.size.height * 0.45)
                    .blur(radius: 65)
                
                // Orb 4: Soft Coral / Pink (Bottom Right)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (colorScheme == .dark ? Color.pink.opacity(0.20) : Color.pink.opacity(0.12)),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                    .frame(width: 380, height: 380)
                    .offset(x: geo.size.width - 200, y: geo.size.height * 0.7)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
        }
    }
}

public struct GlassButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 22, padding: CGFloat = 0, showsBorder: Bool = true) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, padding: padding, showsBorder: showsBorder))
    }
}
