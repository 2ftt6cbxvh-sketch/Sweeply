import SwiftUI

public struct LiquidGlassBackplate: View {
    public var cornerRadius: CGFloat
    public var showsBorder: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var motion = MotionManager.shared
    
    public init(cornerRadius: CGFloat = 22, showsBorder: Bool = true) {
        self.cornerRadius = cornerRadius
        self.showsBorder = showsBorder
    }
    
    public var body: some View {
        // Physical reflection offset from iPhone accelerometer / gyroscope tilt
        let reflectionCenter = UnitPoint(
            x: 0.20 + motion.tiltX * 0.20,
            y: 0.12 + motion.tiltY * 0.20
        )
        let glintStart = UnitPoint(
            x: 0.0 + motion.tiltX * 0.15,
            y: 0.0 + motion.tiltY * 0.15
        )
        let glintEnd = UnitPoint(
            x: 0.60 + motion.tiltX * 0.15,
            y: 0.60 + motion.tiltY * 0.15
        )
        
        ZStack {
            // 1. Quantum Liquid Glass Diffusion Base (Fast single-pass translucent acrylic)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.11, green: 0.11, blue: 0.14).opacity(0.85)
                        : Color.white.opacity(0.72)
                )
            
            // 2. Dynamic Tilt-Responsive Specular Water Dome (Moves naturally with iPhone tilt)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.45),
                            colorScheme == .dark ? Color.white.opacity(0.02) : Color.white.opacity(0.08),
                            Color.clear
                        ],
                        center: reflectionCenter,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
            
            // 3. Dynamic Tilt Specular Glint (Physical ray catch)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: colorScheme == .dark ? Color.white.opacity(0.20) : Color.white.opacity(0.55), location: 0.0),
                            .init(color: Color.clear, location: 0.30)
                        ],
                        startPoint: glintStart,
                        endPoint: glintEnd
                    )
                )
        }
        .overlay {
            if showsBorder {
                // 4. Razor-Thin Specular Lip
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.35 : 0.75), location: 0.0),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25), location: 0.35),
                                .init(color: Color.clear, location: 0.70),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.12 : 0.30), location: 1.0)
                            ],
                            startPoint: glintStart,
                            endPoint: glintEnd
                        ),
                        lineWidth: 0.8
                    )
            }
        }
        // 5. Fast Single-Pass Depth Shadow (120fps smooth scrolling)
        .shadow(
            color: colorScheme == .dark
                ? Color.black.opacity(0.35)
                : Color.black.opacity(0.05),
            radius: 6,
            x: 0,
            y: 2
        )
    }
}

public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var padding: CGFloat
    public var showsBorder: Bool
    
    public init(cornerRadius: CGFloat = 22, padding: CGFloat = 0, showsBorder: Bool = true) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.showsBorder = showsBorder
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                LiquidGlassBackplate(cornerRadius: cornerRadius, showsBorder: showsBorder)
            )
    }
}

public struct AmbientGlassBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // True Deep Dark Canvas in Dark Mode (Pure Apple OLED Black)
            if colorScheme == .dark {
                Color.black
                    .ignoresSafeArea()
            } else {
                Color(red: 0.95, green: 0.96, blue: 0.98)
                    .ignoresSafeArea()
            }
        }
    }
}

public struct GlassButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

public struct SmoothCardButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 22, padding: CGFloat = 0, showsBorder: Bool = true) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, padding: padding, showsBorder: showsBorder))
    }
}

public struct SortControlBar: View {
    @Binding public var sortOrder: MediaSortOrder
    public var itemCount: Int?
    public var selectedBytes: Int64?
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        sortOrder: Binding<MediaSortOrder>,
        itemCount: Int? = nil,
        selectedBytes: Int64? = nil
    ) {
        self._sortOrder = sortOrder
        self.itemCount = itemCount
        self.selectedBytes = selectedBytes
    }
    
    public var body: some View {
        HStack {
            if let count = itemCount {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) items")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    
                    if let bytes = selectedBytes, bytes > 0 {
                        Text("\(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)) selected")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Interactive Liquid Glass Sort Menu
            Menu {
                Picker("Sort Order", selection: $sortOrder) {
                    ForEach(MediaSortOrder.allCases) { order in
                        Label(order.title, systemImage: order.icon)
                            .tag(order)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.blue)
                    
                    Text("Sort: \(sortOrder.shortLabel)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.cyan.opacity(colorScheme == .dark ? 0.20 : 0.15),
                                            Color.purple.opacity(colorScheme == .dark ? 0.10 : 0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            Capsule().stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white, location: 0.0),
                                        .init(color: Color.cyan, location: 0.35),
                                        .init(color: Color.white.opacity(0.3), location: 0.70),
                                        .init(color: Color.pink.opacity(0.6), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                        )
                )
                .shadow(color: Color.cyan.opacity(colorScheme == .dark ? 0.25 : 0.15), radius: 8, x: 0, y: 3)
            }
            .onChange(of: sortOrder) { _, _ in
                HapticService.shared.selection()
            }
        }
        .liquidGlass(cornerRadius: 18, padding: 12)
    }
}

