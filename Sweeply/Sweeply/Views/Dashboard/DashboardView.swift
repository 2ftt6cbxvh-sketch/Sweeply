import SwiftUI
import Photos
import PhotosUI

public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var undoService = UndoService.shared
    @State private var showingPermissionSheet = false
    @State private var showingProfileSheet = false
    @State private var showingShakeUndoAlert = false
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
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic ambient colorful glass backdrop
                AmbientGlassBackdrop()
                
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
                        
                        // Main Storage Progress Ring
                        StorageRingView(breakdown: viewModel.storage)
                            .padding(.horizontal)
                        
                        // Quick Scan Action Button (Luminous Glass Capsule)
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
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.1, green: 0.5, blue: 1.0),
                                            Color(red: 0.35, green: 0.35, blue: 0.98)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.15)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.2
                                        )
                                )
                                .shadow(color: Color.blue.opacity(0.40), radius: 14, x: 0, y: 6)
                            }
                            .buttonStyle(GlassButtonStyle())
                            .disabled(viewModel.isScanning)
                            
                            if viewModel.isScanning {
                                ProgressView(value: viewModel.scanProgress)
                                    .tint(.blue)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .padding(.horizontal)
                    
                    // Category List
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CLEANUP CATEGORIES")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        
                        // 1. Similar Photos
                        NavigationLink {
                            SimilarPhotosView(onCleanRequested: { batch in
                                activeSheet = .review(batch)
                            })
                        } label: {
                            CategoryCardView(
                                icon: "photo.stack.fill",
                                iconColor: .blue,
                                title: "Similar Photos",
                                subtitle: "Group duplicates and bursts",
                                badgeText: viewModel.storage.similarPhotosBytes > 0 ? ByteCountFormatter.string(fromByteCount: viewModel.storage.similarPhotosBytes, countStyle: .file) : nil,
                                countText: "\(viewModel.storage.similarPhotosCount) items",
                                isProcessing: viewModel.isScanning
                            )
                        }
                        .padding(.horizontal)
                        
                        // 2. Screenshots
                        NavigationLink {
                            ScreenshotsView(onCleanRequested: { batch in
                                activeSheet = .review(batch)
                            })
                        } label: {
                            CategoryCardView(
                                icon: "iphone",
                                iconColor: .purple,
                                title: "Screenshots",
                                subtitle: "Old screen captures & receipts",
                                badgeText: viewModel.storage.screenshotsBytes > 0 ? ByteCountFormatter.string(fromByteCount: viewModel.storage.screenshotsBytes, countStyle: .file) : nil,
                                countText: "\(viewModel.storage.screenshotsCount) items",
                                isProcessing: viewModel.isScanning
                            )
                        }
                        .padding(.horizontal)
                        
                        // 3. Large Videos
                        NavigationLink {
                            LargeVideosView(onCleanRequested: { batch in
                                activeSheet = .review(batch)
                            })
                        } label: {
                            CategoryCardView(
                                icon: "video.fill",
                                iconColor: .orange,
                                title: "Large Videos",
                                subtitle: "Sort by size & compress videos",
                                badgeText: viewModel.storage.largeVideosBytes > 0 ? ByteCountFormatter.string(fromByteCount: viewModel.storage.largeVideosBytes, countStyle: .file) : nil,
                                countText: "\(viewModel.storage.largeVideosCount) videos",
                                isProcessing: viewModel.isScanning
                            )
                        }
                        .padding(.horizontal)
                        
                        // 4. Blurry Photos
                        NavigationLink {
                            BlurryPhotosView(onCleanRequested: { batch in
                                activeSheet = .review(batch)
                            })
                        } label: {
                            CategoryCardView(
                                icon: "eye.slash.fill",
                                iconColor: .orange,
                                title: "Blurry Photos",
                                subtitle: "Low-clarity & out-of-focus shots",
                                badgeText: "Vision AI",
                                countText: "Analyze",
                                isProcessing: viewModel.isScanning
                            )
                        }
                        .padding(.horizontal)
                        
                        // 5. Live Photo Optimizer
                        NavigationLink {
                            LivePhotosView()
                        } label: {
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
                        .padding(.horizontal)
                        
                        // 6. Duplicate Contacts
                        NavigationLink {
                            DuplicateContactsView()
                        } label: {
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
                        .padding(.horizontal)
                        
                        // 5. Swipe to Clean (Bonus)
                        NavigationLink {
                            SwipeCleanView(onCleanRequested: { batch in
                                activeSheet = .review(batch)
                            })
                        } label: {
                            CategoryCardView(
                                icon: "hand.draw.fill",
                                iconColor: .pink,
                                title: "Swipe to Clean",
                                subtitle: "Swipe right to keep, left to clean",
                                badgeText: "Bonus",
                                countText: "Fast Deck"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 28)
                }
                .padding(.top, 8)
            }
            }
            .navigationTitle("Sweeply")
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
                            viewModel.refreshStorage()
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
                if let lastAction = undoService.lastCleanAction {
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
