import SwiftUI

public enum AppTab: String, CaseIterable, Identifiable {
    case clean
    case swipe
    case videos
    case contacts
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .clean: return "Clean"
        case .swipe: return "Swipe"
        case .videos: return "Videos"
        case .contacts: return "Contacts"
        }
    }
    
    public var icon: String {
        switch self {
        case .clean: return "sparkles"
        case .swipe: return "rectangle.stack.fill"
        case .videos: return "video.fill"
        case .contacts: return "person.2.fill"
        }
    }
}

public struct MainTabView: View {
    @State private var selectedTab: AppTab = .clean
    @Namespace private var animationNamespace
    @Environment(\.colorScheme) private var colorScheme
    @State private var activeSheet: ActiveTabSheet? = nil
    
    private enum ActiveTabSheet: Identifiable {
        case review(CleanBatch)
        case success(Int64)
        
        var id: String {
            switch self {
            case .review(let b): return "review-\(b.id)"
            case .success(let bytes): return "success-\(bytes)"
            }
        }
    }
    
    public init() {
        if ProcessInfo.processInfo.arguments.contains("-tab-swipe") {
            _selectedTab = State(initialValue: .swipe)
        } else if ProcessInfo.processInfo.arguments.contains("-tab-videos") {
            _selectedTab = State(initialValue: .videos)
        } else if ProcessInfo.processInfo.arguments.contains("-tab-contacts") {
            _selectedTab = State(initialValue: .contacts)
        }
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Viewport (Preserved stack to eliminate lag and re-scanning)
            ZStack {
                DashboardView()
                    .opacity(selectedTab == .clean ? 1 : 0)
                    .allowsHitTesting(selectedTab == .clean)
                
                NavigationStack {
                    SwipeCleanView(onCleanRequested: { batch in
                        activeSheet = .review(batch)
                    })
                    .navigationTitle("Swipe Clean")
                }
                .opacity(selectedTab == .swipe ? 1 : 0)
                .allowsHitTesting(selectedTab == .swipe)
                
                NavigationStack {
                    LargeVideosView(onCleanRequested: { batch in
                        activeSheet = .review(batch)
                    })
                    .navigationTitle("Large Videos")
                }
                .opacity(selectedTab == .videos ? 1 : 0)
                .allowsHitTesting(selectedTab == .videos)
                
                NavigationStack {
                    DuplicateContactsView()
                        .navigationTitle("Duplicate Contacts")
                }
                .opacity(selectedTab == .contacts ? 1 : 0)
                .allowsHitTesting(selectedTab == .contacts)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.16), value: selectedTab)
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let h = value.translation.width
                        let v = value.translation.height
                        // Only fire when clearly horizontal to avoid fighting scroll views
                        guard abs(h) > abs(v) * 1.5, abs(h) > 50 else { return }
                        let tabs = AppTab.allCases
                        guard let idx = tabs.firstIndex(of: selectedTab) else { return }
                        if h < 0, idx < tabs.count - 1 {
                            // Swipe left → next tab
                            HapticService.shared.selection()
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                                selectedTab = tabs[idx + 1]
                            }
                        } else if h > 0, idx > 0 {
                            // Swipe right → previous tab
                            HapticService.shared.selection()
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                                selectedTab = tabs[idx - 1]
                            }
                        }
                    }
            )
            
            // Floating iOS 26/27 Liquid Glass Bottom Navigation Bar
            liquidBottomNavBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .review(let batch):
                ReviewDeleteView(batch: batch) { freedBytes in
                    activeSheet = .success(freedBytes)
                }
            case .success(let freedBytes):
                CleanSuccessView(freedBytes: freedBytes) {
                    activeSheet = nil
                }
            }
        }
    }
    
    // MARK: - Floating Liquid Glass Dock
    private var liquidBottomNavBar: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            ZStack {
                // Dock Base: Liquid frosted diffusion
                Capsule()
                    .fill(.ultraThinMaterial)
                
                // Dock Optical Tint (Clean water highlight)
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.45), location: 0.0),
                                .init(color: Color.clear, location: 0.40),
                                .init(color: colorScheme == .dark ? Color.white.opacity(0.04) : Color.blue.opacity(0.03), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Dock Specular Bevel Border (Subtle crystal rim)
                Capsule()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.80), location: 0.0),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.15 : 0.35), location: 0.35),
                                .init(color: Color.clear, location: 0.65),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.20 : 0.40), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            }
            // Natural suspended shadow
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.45) : Color(red: 0.08, green: 0.14, blue: 0.25).opacity(0.12),
                radius: 20,
                x: 0,
                y: 8
            )
            .shadow(
                color: Color.white.opacity(colorScheme == .dark ? 0.10 : 0.60),
                radius: 1,
                x: 0,
                y: -1
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }
    
    // MARK: - Individual Tab Item with iOS 27 Liquid Glass Selection Pill
    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        
        Button {
            if selectedTab != tab {
                HapticService.shared.selection()
                withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                    selectedTab = tab
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: tab.icon)
                    .font(.system(size: isSelected ? 16 : 17, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? (colorScheme == .dark ? Color.white : Color(red: 0.05, green: 0.40, blue: 0.95)) : Color.secondary)
                
                if isSelected {
                    Text(tab.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 0.05, green: 0.40, blue: 0.95))
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .padding(.horizontal, isSelected ? 16 : 12)
            .padding(.vertical, 10)
            .frame(minHeight: 42)
            .background {
                if isSelected {
                    // iOS 27 Liquid Glass Selection Pill (Physics Droplet Architecture)
                    ZStack {
                        // 1. High-Refraction Liquid Lens Base
                        Capsule()
                            .fill(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.18)
                                    : Color.white.opacity(0.85)
                            )
                        
                        // 2. Optical Water-Tension Droplet Reflection
                        Capsule()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        colorScheme == .dark ? Color.white.opacity(0.30) : Color.white.opacity(0.70),
                                        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.18),
                                        Color.clear
                                    ],
                                    center: UnitPoint(x: 0.25, y: 0.15),
                                    startRadius: 0,
                                    endRadius: 45
                                )
                            )
                        
                        // 3. Subtle Liquid Hue Refraction (Apple Blue/Cyan Whisper)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: colorScheme == .dark ? Color.blue.opacity(0.20) : Color.blue.opacity(0.10), location: 0.0),
                                        .init(color: Color.clear, location: 0.50),
                                        .init(color: colorScheme == .dark ? Color.cyan.opacity(0.10) : Color.cyan.opacity(0.06), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // 4. Sharp 45° Specular Glint
                        Capsule()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: colorScheme == .dark ? Color.white.opacity(0.40) : Color.white.opacity(0.75), location: 0.0),
                                        .init(color: colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.20), location: 0.25),
                                        .init(color: Color.clear, location: 0.45)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // 5. Razor-Thin Specular Meniscus Rim
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.75 : 0.95), location: 0.0),
                                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.25 : 0.45), location: 0.35),
                                        .init(color: Color.clear, location: 0.65),
                                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.30 : 0.55), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                    }
                    // Liquid droplet tactile depth
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.35) : Color(red: 0.08, green: 0.14, blue: 0.25).opacity(0.10),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                    .shadow(
                        color: Color.white.opacity(colorScheme == .dark ? 0.15 : 0.65),
                        radius: 1,
                        x: 0,
                        y: -1
                    )
                    .matchedGeometryEffect(id: "activeTabPill", in: animationNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
