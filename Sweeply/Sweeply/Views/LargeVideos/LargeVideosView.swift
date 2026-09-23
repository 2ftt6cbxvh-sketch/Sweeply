import SwiftUI
import Photos

public struct LargeVideosView: View {
    @StateObject private var viewModel = LargeVideosViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @State private var previewAsset: MediaAsset? = nil
    public let onCleanRequested: (CleanBatch) -> Void
    
    public init(onCleanRequested: @escaping (CleanBatch) -> Void) {
        self.onCleanRequested = onCleanRequested
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if !permissionService.hasPhotosAccess {
                    PermissionNoticeView(
                        title: "Photo Access Required",
                        message: "Sweeply needs access to find and clean large video files.",
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
                    ProgressView("Loading videos...")
                        .frame(maxHeight: .infinity)
                } else if viewModel.videos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        Text("No Videos Found")
                            .font(.title2.weight(.bold))
                        
                        Text("You don't have any video files occupying storage.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Header controls with Liquid Glass Sort Bar
                            SortControlBar(
                                sortOrder: $viewModel.sortOrder,
                                itemCount: viewModel.videos.count,
                                selectedBytes: viewModel.selectedSavingsBytes
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            
                            HStack {
                                Spacer()
                                Button(viewModel.selectedIds.count == viewModel.videos.count ? "Deselect All" : "Select All") {
                                    if viewModel.selectedIds.count == viewModel.videos.count {
                                        viewModel.deselectAll()
                                    } else {
                                        viewModel.selectAll()
                                    }
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.orange)
                            }
                            .padding(.horizontal, 16)
                            
                            // Video rows
                            ForEach(viewModel.sortedVideos) { asset in
                                let isSelected = viewModel.selectedIds.contains(asset.id)
                                
                                HStack(spacing: 14) {
                                    // Thumbnail with Play overlay
                                    Button {
                                        previewAsset = asset
                                    } label: {
                                        ZStack {
                                            ThumbnailImageView(asset: asset.phAsset, targetSize: CGSize(width: 180, height: 180))
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(12)
                                                .clipped()
                                            
                                            Circle()
                                                .fill(Color.black.opacity(0.5))
                                                .frame(width: 28, height: 28)
                                            
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // Details
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(asset.formattedSize)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            
                                            Spacer()
                                            
                                            Text(asset.formattedDuration)
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.secondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(uiColor: .tertiarySystemFill))
                                                .cornerRadius(6)
                                        }
                                        
                                        Text(asset.formattedDate)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        // Bonus Compress button
                                        Button {
                                            viewModel.selectedVideoForCompress = asset
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                                Text("Compress")
                                            }
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.blue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(6)
                                        }
                                        .padding(.top, 2)
                                    }
                                    
                                    // Selection checkbox
                                    Button {
                                        viewModel.toggleSelection(for: asset.id)
                                    } label: {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 24))
                                            .foregroundStyle(isSelected ? .orange : .gray.opacity(0.5))
                                    }
                                    .padding(.leading, 4)
                                }
                                .liquidGlass(cornerRadius: 16, padding: 12)
                                .padding(.horizontal)
                            }
                            
                            Spacer()
                                .frame(height: 90)
                        }
                    }
                }
            }
            
            // Bottom Sticky Clean Bar
            if !viewModel.selectedIds.isEmpty {
                VStack {
                    Button {
                        if let batch = viewModel.prepareCleanBatch() {
                            onCleanRequested(batch)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clean \(viewModel.selectedIds.count) Videos (\(viewModel.formattedSavings))")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.orange)
                        .cornerRadius(16)
                        .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .liquidGlass(cornerRadius: 20, padding: 12)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(AmbientGlassBackdrop())
        .navigationTitle("Large Videos")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $previewAsset) { asset in
            VideoPreviewSheet(asset: asset)
        }
        .sheet(item: $viewModel.selectedVideoForCompress) { asset in
            VideoCompressSheet(asset: asset, viewModel: viewModel)
        }
        .task {
            permissionService.checkCurrentStatuses()
            if permissionService.hasPhotosAccess && viewModel.videos.isEmpty {
                viewModel.load()
            }
        }
    }
}
