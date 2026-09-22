import SwiftUI
import Photos
import PhotosUI

public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingPermissionSheet = false
    @State private var showingProfileSheet = false
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
                        .padding(12)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Main Storage Progress Ring
                    StorageRingView(breakdown: viewModel.storage)
                        .padding(.horizontal)
                    
                    // Quick Scan Action Button
                    VStack(spacing: 8) {
                        Button {
                            Task {
                                await handleScanTapped()
                            }
                        } label: {
                            HStack {
                                Image(systemName: viewModel.isScanning ? "arrow.triangle.2.circlepath" : "sparkles")
                                    .rotationEffect(.degrees(viewModel.isScanning ? 360 : 0))
                                    .animation(viewModel.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isScanning)
                                
                                Text(viewModel.isScanning ? "Scanning Library..." : "Run Smart Scan")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color(red: 0.2, green: 0.4, blue: 0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.28), radius: 8, x: 0, y: 4)
                        }
                        .disabled(viewModel.isScanning)
                        
                        if viewModel.isScanning {
                            ProgressView(value: viewModel.scanProgress)
                                .tint(.blue)
                                .padding(.horizontal, 4)
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
                        
                        // 4. Duplicate Contacts
                        NavigationLink {
                            DuplicateContactsView()
                        } label: {
                            CategoryCardView(
                                icon: "person.2.fill",
                                iconColor: .green,
                                title: "Duplicate Contacts",
                                subtitle: "Merge or clean repeated contacts",
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
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Sweeply")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingProfileSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(authService.isAuthenticated && authService.currentUser?.provider != .guest ? Color.blue : Color(uiColor: .systemGray4))
                                    .frame(width: 32, height: 32)
                                
                                if let user = authService.currentUser, authService.isAuthenticated && user.provider != .guest {
                                    if user.provider == .apple {
                                        Image(systemName: "apple.logo")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white)
                                    } else {
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white)
                                    }
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            themeManager.toggleTheme()
                        } label: {
                            Image(systemName: themeManager.currentTheme == .dark ? "moon.stars.fill" : "sun.max.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(themeManager.currentTheme == .dark ? Color.yellow : Color.orange)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        
                        Button {
                            viewModel.refreshStorage()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15, weight: .semibold))
                        }
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
            .task {
                if permissionService.hasPhotosAccess {
                    await viewModel.runQuickScan()
                }
            }
        }
    }
    
    private func handleScanTapped() async {
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
