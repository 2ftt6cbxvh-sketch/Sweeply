import SwiftUI
import Photos
import PhotosUI

public enum DashboardRoute: Hashable, Identifiable {
    case similarPhotos
    case screenshots
    case largeVideos
    case blurryPhotos
    case livePhotos
    case duplicateContacts
    case swipeClean
    
    public var id: Self { self }
}

public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var undoService = UndoService.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingPermissionSheet = false
    @State private var showingProfileSheet = false
    @State private var showingShakeUndoAlert = false
    @State private var navigationPath = NavigationPath()
    @State private var activeSheet: ActiveDashboardSheet? = nil
    
    private enum ActiveDashboardSheet: Identifiable {
        case review(CleanBatch)
        case success(Int64)
        case settings
        
        var id: String {
            switch self {
            case .review(let b): return "review-\(b.id)"
            case .success(let bytes): return "success-\(bytes)"
            case .settings: return "settings"
            }
        }
    }
    
    public init() {
        var path = NavigationPath()
        if ProcessInfo.processInfo.arguments.contains("-route-blurry") {
            path.append(DashboardRoute.blurryPhotos)
            _navigationPath = State(initialValue: path)
        } else if ProcessInfo.processInfo.arguments.contains("-route-livephotos") {
            path.append(DashboardRoute.livePhotos)
            _navigationPath = State(initialValue: path)
        } else if ProcessInfo.processInfo.arguments.contains("-route-similar") {
            path.append(DashboardRoute.similarPhotos)
            _navigationPath = State(initialValue: path)
        } else if ProcessInfo.processInfo.arguments.contains("-route-screenshots") {
            path.append(DashboardRoute.screenshots)
            _navigationPath = State(initialValue: path)
        }
    }
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Dynamic ambient colorful glass backdrop
                AmbientGlassBackdrop()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            // Limited Permission Alert Banner (if user selected limited photos)
                            if permissionService.isPhotosLimited {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Limited library access active. Tap to select more photos.")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Button("Edit") {
                                        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: UIApplication.shared.topMostViewController() ?? UIViewController())
                                    }
                                    .font(.caption.weight(.bold))
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)
                                }
                                .liquidGlass(cornerRadius: 16, padding: 12)
                                .padding(.horizontal)
                            }
                            
                            // 1. Standout Storage Intelligence Partition (Controls + Dynamic Charts + Floating Circle Progress Ring)
                            StoragePartitionView(breakdown: viewModel.storage)
                                .padding(.horizontal)
                            
                            // 2. Quick Scan Action Button (Luminous Glass Capsule)
                            quickScanButton
                            
                            // 3. Category List with Size Sort Indicator
                            cleanupCategoriesSection
                            
                            // 4. Recommendations Section at the Bottom
                            DashboardRecommendationsView(breakdown: viewModel.storage) { route in
                                HapticService.shared.selection()
                                navigationPath.append(route)
                            }
                            .id("recommendationsBottom")
                            .padding(.horizontal)
                            .padding(.bottom, 140)
                        }
                        .padding(.top, 8)
                    }
                    .task {
                        if ProcessInfo.processInfo.arguments.contains("-scroll-recommendations") {
                            try? await Task.sleep(nanoseconds: 600_000_000)
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("recommendationsBottom", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Storage Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: DashboardRoute.self) { route in
                switch route {
                case .similarPhotos:
                    SimilarPhotosView(onCleanRequested: { batch in activeSheet = .review(batch) })
                case .screenshots:
                    ScreenshotsView(onCleanRequested: { batch in activeSheet = .review(batch) })
                case .largeVideos:
                    LargeVideosView(onCleanRequested: { batch in activeSheet = .review(batch) })
                case .blurryPhotos:
                    BlurryPhotosView(onCleanRequested: { batch in activeSheet = .review(batch) })
                case .livePhotos:
                    LivePhotosView()
                case .duplicateContacts:
                    DuplicateContactsView()
                case .swipeClean:
                    SwipeCleanView(onCleanRequested: { batch in activeSheet = .review(batch) })
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingProfileSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                            
                            if let user = authService.currentUser, authService.isAuthenticated && user.provider != .guest {
                                if user.provider == .apple {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.primary)
                                } else {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.red)
                                }
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primary)
                            }
                        }
                        .shadow(color: Color.black.opacity(0.06), radius: 6)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        Button {
                            themeManager.toggleTheme()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                                
                                Image(systemName: themeManager.currentTheme == .dark ? "moon.stars.fill" : "sun.max.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(themeManager.currentTheme == .dark ? Color.yellow : Color.orange)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .shadow(color: Color.black.opacity(0.06), radius: 6)
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button {
                            Task {
                                await viewModel.runQuickScan()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                                
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                            }
                            .shadow(color: Color.black.opacity(0.06), radius: 6)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }
            }
            .sheet(isPresented: $showingProfileSheet) {
                UserProfileSheet()
            }
            .refreshable {
                await viewModel.runQuickScan()
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .review(let batch):
                    ReviewDeleteView(batch: batch) { freedBytes in
                        activeSheet = .success(freedBytes)
                        viewModel.onCleaningFinished(freedBytes: freedBytes)
                    }
                case .success(let freedBytes):
                    CleanSuccessView(freedBytes: freedBytes) {
                        activeSheet = nil
                    }
                case .settings:
                    Text("Settings")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                HapticService.shared.notification(.warning)
                showingShakeUndoAlert = true
            }
            .alert("Shake to Undo Detected", isPresented: $showingShakeUndoAlert) {
                if undoService.lastCleanAction != nil {
                    Button("Clear History") {
                        undoService.clearLastAction()
                    }
                }
                Button("Got it", role: .cancel) {}
            } message: {
                if let lastAction = undoService.lastCleanAction {
                    Text("Recent Action: \(lastAction.title) (\(lastAction.itemCount) item(s)).\n\nYour items are kept in Apple's 'Recently Deleted' album for 30 days. You can open Photos at any time to restore them.")
                } else {
                    Text("Sweeply uses Apple's official 'Recently Deleted' recovery net. Any photo or video cleaned is safely recoverable for 30 days.")
                }
            }
            .task {
                permissionService.checkCurrentStatuses()
                if permissionService.hasPhotosAccess {
                    await viewModel.runQuickScan()
                }
            }
        }
    }
    
    private func handleScanTapped() async {
        HapticService.shared.impact(.medium)
        if !permissionService.hasPhotosAccess {
            let status = await permissionService.requestPhotosPermission()
            if status == .authorized || status == .limited {
                await viewModel.runQuickScan()
            }
        } else {
            await viewModel.runQuickScan()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var quickScanButton: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    await handleScanTapped()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isScanning ? "arrow.triangle.2.circlepath" : "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .rotationEffect(.degrees(viewModel.isScanning ? 360 : 0))
                        .animation(viewModel.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isScanning)
                    
                    Text(viewModel.isScanning ? "Scanning Storage..." : "Run Smart Clean Scan")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.48, blue: 0.98),
                            Color(red: 0.02, green: 0.36, blue: 0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.0)
                )
                .shadow(color: Color(red: 0.05, green: 0.35, blue: 0.85).opacity(0.40), radius: 14, x: 0, y: 7)
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(viewModel.isScanning)
            
            if let lastScan = viewModel.lastScanDate {
                Text("Last analyzed \(lastScan.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var cleanupCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("CLEANUP CATEGORIES")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Size")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            
            // 1. Similar Photos
            NavigationLink(value: DashboardRoute.similarPhotos) {
                CategoryCardView(
                    icon: "photo.stack.fill",
                    iconColor: .blue,
                    title: "Similar Photos",
                    subtitle: "Group duplicates and bursts",
                    badgeText: viewModel.storage.similarPhotosBytes > 0 ? ByteCountFormatter.string(fromByteCount: viewModel.storage.similarPhotosBytes, countStyle: .file) : nil,
                    countText: "\(viewModel.storage.similarPhotosCount) items",
                    percentageText: viewModel.storage.similarPhotosBytes > 0 ? viewModel.storage.formattedPercentageOfFilledStorage(bytes: viewModel.storage.similarPhotosBytes) : nil,
                    isProcessing: viewModel.isScanning
                )
            }
            .buttonStyle(SmoothCardButtonStyle())
            .padding(.horizontal)
            
            // 2. Screenshots
            NavigationLink(value: DashboardRoute.screenshots) {
                CategoryCardView(
                    icon: "iphone",
                    iconColor: .purple,
                    title: "Screenshots",
                    subtitle: "Old screen captures & receipts",
                    badgeText: viewModel.storage.screenshotsBytes > 0 ? ByteCountFormatter.string(fromByteCount: viewModel.storage.screenshotsBytes, countStyle: .file) : nil,
                    countText: "\(viewModel.storage.screenshotsCount) items",
                    percentageText: viewModel.storage.screenshotsBytes > 0 ? viewModel.storage.formattedPercentageOfFilledStorage(bytes: viewModel.storage.screenshotsBytes) : nil,
                    isProcessing: viewModel.isScanning
                )
            }
            .buttonStyle(SmoothCardButtonStyle())
            .padding(.horizontal)
            
            // 3. Large Videos
            NavigationLink(value: DashboardRoute.largeVideos) {
                CategoryCardView(
                    icon: "video.fill",
                    iconColor: .orange,
                    title: "Large Videos",
                    subtitle: "Sort by size & compress videos",
                    badgeText: viewModel.storage.largeVideosBytes > 0 ? ByteCountFormatter.string(fromByteCount: viewModel.storage.largeVideosBytes, countStyle: .file) : nil,
                    countText: "\(viewModel.storage.largeVideosCount) videos",
                    percentageText: viewModel.storage.largeVideosBytes > 0 ? viewModel.storage.formattedPercentageOfFilledStorage(bytes: viewModel.storage.largeVideosBytes) : nil,
                    isProcessing: viewModel.isScanning
                )
            }
            .buttonStyle(SmoothCardButtonStyle())
            .padding(.horizontal)
            
            // 4. Blurry Photos
            NavigationLink(value: DashboardRoute.blurryPhotos) {
                CategoryCardView(
                    icon: "eye.slash.fill",
                    iconColor: .orange,
                    title: "Blurry Photos",
                    subtitle: "Low-clarity & out-of-focus shots",
                    badgeText: "Vision AI",
                    countText: "Analyze",
                    percentageText: viewModel.storage.blurryPhotosBytes > 0 ? viewModel.storage.formattedPercentageOfFilledStorage(bytes: viewModel.storage.blurryPhotosBytes) : nil,
                    isProcessing: viewModel.isScanning
                )
            }
            .buttonStyle(SmoothCardButtonStyle())
            .padding(.horizontal)
            
            // 5. Live Photo Optimizer
            NavigationLink(value: DashboardRoute.livePhotos) {
                CategoryCardView(
                    icon: "livephoto",
                    iconColor: .cyan,
                    title: "Live Photo Optimizer",
                    subtitle: "Strip video & save ~70% storage",
                    badgeText: "Save 70%",
                    countText: "Convert",
                    isProcessing: viewModel.isScanning
                )
            }
            .buttonStyle(SmoothCardButtonStyle())
            .padding(.horizontal)
            
            // 6. Duplicate Contacts
            NavigationLink(value: DashboardRoute.duplicateContacts) {
                CategoryCardView(
                    icon: "person.2.fill",
                    iconColor: .green,
                    title: "Duplicate Contacts",
                    subtitle: "Merge duplicates & purge incomplete",
                    badgeText: "\(viewModel.storage.duplicateContactsSets) sets",
                    countText: "\(viewModel.storage.duplicateContactsCount) contacts",
                    isProcessing: viewModel.isScanning
                )
            }
            .buttonStyle(SmoothCardButtonStyle())
            .padding(.horizontal)
            
            // 7. Swipe to Clean (Bonus)
            NavigationLink(value: DashboardRoute.swipeClean) {
                CategoryCardView(
                    icon: "hand.draw.fill",
                    iconColor: .pink,
                    title: "Swipe to Clean",
                    subtitle: "Swipe right to keep, left to clean",
                    badgeText: "Bonus",
                    countText: "Fast Deck"
                )
            }
            .buttonStyle(SmoothCardButtonStyle())
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
}

extension UIApplication {
    func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        
        if let nav = root as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topMostViewController(base: selected)
        }
        if let presented = root?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return root
    }
}
