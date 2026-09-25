import SwiftUI

public struct ScreenshotsView: View {
    @StateObject private var viewModel = ScreenshotsViewModel()
    @StateObject private var permissionService = PermissionService.shared
    public let onCleanRequested: (CleanBatch) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    public init(onCleanRequested: @escaping (CleanBatch) -> Void) {
        self.onCleanRequested = onCleanRequested
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if !permissionService.hasPhotosAccess {
                    PermissionNoticeView(
                        title: "Photo Access Required",
                        message: "Sweeply needs access to find and clean screenshots.",
                        isDenied: permissionService.photoStatus == .denied
                    ) {
                        if permissionService.photoStatus == .denied {
                            permissionService.openSettings()
                        } else {
                            Task {
                                _ = await permissionService.requestPhotosPermission()
                                viewModel.load()
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.isLoading {
                    ProgressView("Loading screenshots...")
                        .frame(maxHeight: .infinity)
                } else if viewModel.screenshots.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "iphone.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.purple)
                        
                        Text("No Screenshots Found")
                            .font(.title2.weight(.bold))
                        
                        Text("You don't have any screenshots cluttering your storage.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Header controls with Liquid Glass Sort Bar
                            SortControlBar(
                                sortOrder: $viewModel.sortOrder,
                                itemCount: viewModel.totalCount,
                                selectedBytes: viewModel.selectedSavingsBytes
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            
                            HStack {
                                Spacer()
                                Button(viewModel.selectedCount == viewModel.totalCount ? "Deselect All" : "Select All") {
                                    if viewModel.selectedCount == viewModel.totalCount {
                                        viewModel.deselectAll()
                                    } else {
                                        viewModel.selectAll()
                                    }
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.purple)
                            }
                            .padding(.horizontal, 16)
                            
                            // Photo Grid
                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(viewModel.sortedScreenshots) { asset in
                                    let isSelected = viewModel.selectedIds.contains(asset.id)
                                    
                                    Button {
                                        viewModel.toggleSelection(for: asset.id)
                                    } label: {
                                        ZStack(alignment: .topTrailing) {
                                            ThumbnailImageView(asset: asset.phAsset, targetSize: CGSize(width: 300, height: 400))
                                                .aspectRatio(9/16, contentMode: .fit)
                                                .cornerRadius(6)
                                            
                                            // Selection Circle
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 22))
                                                .foregroundStyle(isSelected ? .purple : .white)
                                                .background(Circle().fill(Color.black.opacity(0.3)))
                                                .padding(6)
                                            
                                            // Bottom size badge
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Text(asset.formattedSize)
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 2)
                                                        .background(Color.black.opacity(0.6))
                                                        .cornerRadius(4)
                                                        .padding(4)
                                                }
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            Spacer()
                                .frame(height: 175)
                        }
                    }
                }
            }
            
            // Bottom Sticky Clean Bar
            if viewModel.selectedCount > 0 {
                VStack {
                    Button {
                        if let batch = viewModel.prepareCleanBatch() {
                            onCleanRequested(batch)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clean \(viewModel.selectedCount) Screenshots (\(viewModel.formattedSavings))")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.purple)
                        .cornerRadius(16)
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .liquidGlass(cornerRadius: 20, padding: 12)
                .padding(.horizontal)
                .padding(.bottom, 94)
            }
        }
        .background(AmbientGlassBackdrop())
        .navigationTitle("Screenshots")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            permissionService.checkCurrentStatuses()
            if permissionService.hasPhotosAccess && viewModel.screenshots.isEmpty {
                viewModel.load()
            }
        }
    }
}
