import SwiftUI

public struct LivePhotosView: View {
    @StateObject private var viewModel = LivePhotosViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @State private var showingConvertConfirmation = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    public init() {}
    
    public var body: some View {
        Group {
            if !permissionService.hasPhotosAccess {
                PermissionNoticeView(
                    title: "Photos Access Required",
                    message: "Sweeply scans on-device to find Live Photos and convert them into space-saving stills.",
                    isDenied: permissionService.isPhotosDenied
                ) {
                    if permissionService.isPhotosDenied {
                        permissionService.openSettings()
                    } else {
                        Task {
                            let granted = await permissionService.requestPhotosPermission()
                            if granted == .authorized || granted == .limited {
                                await viewModel.load()
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else if viewModel.isLoading {
                ProgressView("Analyzing Live Photos...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.livePhotos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "livephoto.badge.automatic")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("No Live Photos Found")
                        .font(.title2.weight(.bold))
                    
                    Text("Your library has no motion-heavy Live Photos.")
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
                            Text("\(viewModel.livePhotos.count) Live Photos")
                                .font(.headline)
                            Text("Save ~\(ByteCountFormatter.string(fromByteCount: viewModel.selectedTotalReclaimable, countStyle: .file)) by stripping video")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.toggleSelectAll()
                        } label: {
                            Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.cyan)
                        }
                    }
                    .liquidGlass(cornerRadius: 16, padding: 14)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.livePhotos) { item in
                                let isSelected = viewModel.selectedIds.contains(item.id)
                                
                                Button {
                                    viewModel.toggleSelection(for: item.id)
                                } label: {
                                    ZStack(alignment: .bottomLeading) {
                                        ThumbnailImageView(asset: item.phAsset, targetSize: CGSize(width: 300, height: 300))
                                            .aspectRatio(1, contentMode: .fill)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .clipped()
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 3)
                                            )
                                        
                                        // Live Photo badge
                                        HStack(spacing: 4) {
                                            Image(systemName: "livephoto")
                                                .font(.system(size: 10))
                                            Text("Save \(ByteCountFormatter.string(fromByteCount: item.reclaimableBytes, countStyle: .file))")
                                                .font(.caption2.weight(.bold))
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                        .padding(8)
                                        
                                        // Checkmark
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 22))
                                                    .foregroundStyle(isSelected ? Color.cyan : Color.white)
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
                    
                    // Convert Action Button
                    if !viewModel.selectedIds.isEmpty {
                        VStack {
                            Button {
                                HapticService.shared.impact(.medium)
                                showingConvertConfirmation = true
                            } label: {
                                HStack(spacing: 8) {
                                    if viewModel.isConverting {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    }
                                    Text("Convert \(viewModel.selectedIds.count) to Stills (Reclaim ~\(ByteCountFormatter.string(fromByteCount: viewModel.selectedTotalReclaimable, countStyle: .file)))")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.cyan)
                                .cornerRadius(16)
                                .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(viewModel.isConverting)
                        }
                        .liquidGlass(cornerRadius: 20, padding: 12)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Live Photo Optimizer")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Convert Live Photos to Stills",
            isPresented: $showingConvertConfirmation,
            titleVisibility: .visible
        ) {
            Button("Convert \(viewModel.selectedIds.count) Photos (Keep Best Still)") {
                Task {
                    await viewModel.convertSelected()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This preserves your high-resolution photo while deleting the heavy 3-second background video clip. Reclaims ~70% space.")
        }
        .task {
            if permissionService.hasPhotosAccess && viewModel.livePhotos.isEmpty {
                await viewModel.load()
            }
        }
    }
}
