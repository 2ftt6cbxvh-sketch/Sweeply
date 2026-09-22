import SwiftUI

public struct BlurryPhotosView: View {
    @StateObject private var viewModel = BlurryPhotosViewModel()
    @StateObject private var permissionService = PermissionService.shared
    public let onCleanRequested: (CleanBatch) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    public init(onCleanRequested: @escaping (CleanBatch) -> Void) {
        self.onCleanRequested = onCleanRequested
    }
    
    public var body: some View {
        Group {
            if !permissionService.hasPhotosAccess {
                PermissionNoticeView(
                    title: "Photo Access Required",
                    message: "Sweeply scans on-device to detect out-of-focus or low-clarity photos.",
                    isDenied: permissionService.isPhotosDenied
                ) {
                    if permissionService.isPhotosDenied {
                        permissionService.openSettings()
                    } else {
                        Task {
                            let granted = await permissionService.requestPhotosPermission()
                            if granted == .authorized || granted == .limited {
                                await viewModel.scan()
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else if viewModel.isScanning {
                VStack(spacing: 16) {
                    ProgressView(value: viewModel.scanProgress)
                        .tint(.orange)
                        .padding(.horizontal, 40)
                    
                    Text("Scanning Clarity & Focus...")
                        .font(.headline)
                    
                    Text("\(Int(viewModel.scanProgress * 100))% • Laplacian Edge Variance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if viewModel.blurryAssets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "camera.metering.matrix")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("No Blurry Photos Found")
                        .font(.title2.weight(.bold))
                    
                    Text("All your photos have sharp edge definition and focus.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Header control bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.blurryAssets.count) Blurry Photos")
                                .font(.headline)
                            Text("\(ByteCountFormatter.string(fromByteCount: viewModel.selectedTotalBytes, countStyle: .file)) selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.toggleSelectAll()
                        } label: {
                            Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.orange)
                        }
                    }
                    .liquidGlass(cornerRadius: 16, padding: 14)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.blurryAssets) { asset in
                                let isSelected = viewModel.selectedAssetIds.contains(asset.id)
                                
                                Button {
                                    viewModel.toggleSelection(for: asset.id)
                                } label: {
                                    ZStack(alignment: .bottomLeading) {
                                        ThumbnailImageView(asset: asset.phAsset, targetSize: CGSize(width: 300, height: 300))
                                            .aspectRatio(1, contentMode: .fill)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .clipped()
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 3)
                                            )
                                        
                                        // Clarity Badge
                                        HStack(spacing: 4) {
                                            Image(systemName: "eye.slash.fill")
                                                .font(.system(size: 10))
                                            Text("Low Clarity")
                                                .font(.caption2.weight(.bold))
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                        .padding(8)
                                        
                                        // Selection checkmark
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 22))
                                                    .foregroundStyle(isSelected ? Color.orange : Color.white)
                                                    .shadow(radius: 2)
                                                    .padding(8)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 90)
                    }
                    
                    // Clean Action Bar
                    if !viewModel.selectedAssetIds.isEmpty {
                        VStack {
                            Button {
                                HapticService.shared.impact(.medium)
                                onCleanRequested(viewModel.createCleanBatch())
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash.fill")
                                    Text("Clean \(viewModel.selectedAssetIds.count) Blurry Photos (\(ByteCountFormatter.string(fromByteCount: viewModel.selectedTotalBytes, countStyle: .file)))")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.orange)
                                .cornerRadius(16)
                                .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .liquidGlass(cornerRadius: 20, padding: 12)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Blurry Photos")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if permissionService.hasPhotosAccess && viewModel.blurryAssets.isEmpty {
                await viewModel.scan()
            }
        }
    }
}
