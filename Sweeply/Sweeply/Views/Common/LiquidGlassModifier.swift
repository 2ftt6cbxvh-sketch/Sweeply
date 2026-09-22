import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var padding: CGFloat
    public var showsBorder: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(cornerRadius: CGFloat = 20, padding: CGFloat = 0, showsBorder: Bool = true) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.showsBorder = showsBorder
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if showsBorder {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: colorScheme == .dark
                                            ? [Color.white.opacity(0.22), Color.white.opacity(0.04), Color.clear]
                                            : [Color.white.opacity(0.75), Color.white.opacity(0.2), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.06),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            }
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, padding: CGFloat = 0, showsBorder: Bool = true) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, padding: padding, showsBorder: showsBorder))
    }
}
