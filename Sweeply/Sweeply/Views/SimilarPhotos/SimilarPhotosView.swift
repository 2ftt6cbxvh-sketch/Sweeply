import SwiftUI

public struct SimilarPhotosView: View {
    @StateObject private var viewModel = SimilarPhotosViewModel()
    @StateObject private var permissionService = PermissionService.shared
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
                        message: "Sweeply needs access to your photos to identify duplicate and similar shots.",
                        isDenied: permissionService.photoStatus == .denied
                    ) {
                        if permissionService.photoStatus == .denied {
                            permissionService.openSettings()
                        } else {
                            Task {
                                _ = await permissionService.requestPhotosPermission()
                                await viewModel.scan()
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.isScanning {
                    VStack(spacing: 20) {
                        ProgressView(value: viewModel.scanProgress)
                            .tint(.blue)
                            .padding(.horizontal, 40)
                        
                        Text("Analyzing photo library for duplicates...")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("\(Int(viewModel.scanProgress * 100))% complete")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.groups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        
                        Text("No Duplicates Found")
                            .font(.title2.weight(.bold))
                        
                        Text("Your photo library is clean! Check back after taking new photos.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Scan Again") {
                            Task {
                                await viewModel.scan()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .padding(.top, 8)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Top Action bar
                            HStack {
                                Text("\(viewModel.groups.count) Groups · \(viewModel.totalDuplicatesFound) Duplicates")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Button("Select All") {
                                    viewModel.selectAllDuplicates()
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.blue)
                                
                                Text("•")
                                    .foregroundStyle(.tertiary)
                                
                                Button("Deselect") {
                                    viewModel.deselectAll()
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            
                            ForEach(Array(viewModel.groups.enumerated()), id: \.element.id) { index, group in
                                SimilarGroupRowView(
                                    group: group,
                                    onToggleSelection: { assetId in
                                        viewModel.toggleSelection(groupIndex: index, assetId: assetId)
                                    },
                                    onMarkAsBest: { assetId in
                                        viewModel.markAsBest(groupIndex: index, assetId: assetId)
                                    }
                                )
                                .padding(.horizontal)
                            }
                            
                            // Bottom padding for sticky button
                            Spacer()
                                .frame(height: 90)
                        }
                    }
                }
            }
            
            // Bottom Sticky Action Bar
            if !viewModel.groups.isEmpty && viewModel.totalSelectedCount > 0 {
                VStack {
                    Button {
                        if let batch = viewModel.prepareCleanBatch() {
                            onCleanRequested(batch)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clean \(viewModel.totalSelectedCount) Photos (\(viewModel.formattedSavings))")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.blue)
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
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
        .navigationTitle("Similar Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.scan()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isScanning)
            }
        }
        .task {
            if permissionService.hasPhotosAccess && viewModel.groups.isEmpty {
                await viewModel.scan()
            }
        }
    }
}
