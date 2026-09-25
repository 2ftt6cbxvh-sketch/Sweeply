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
                            // Top Liquid Glass Sort Bar
                            SortControlBar(
                                sortOrder: $viewModel.sortOrder,
                                itemCount: viewModel.groups.count,
                                selectedBytes: viewModel.totalSavingsBytes
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            
                            HStack {
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
                            
                            ForEach(viewModel.sortedGroups) { group in
                                SimilarGroupRowView(
                                    group: group,
                                    onToggleSelection: { assetId in
                                        viewModel.toggleSelection(groupId: group.id, assetId: assetId)
                                    },
                                    onMarkAsBest: { assetId in
                                        viewModel.markAsBest(groupId: group.id, assetId: assetId)
                                    }
                                )
                                .padding(.horizontal)
                            }
                            
                            // Bottom padding for sticky button
                            Spacer()
                                .frame(height: 175)
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
                }
                .liquidGlass(cornerRadius: 20, padding: 12)
                .padding(.horizontal)
                .padding(.bottom, 94)
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
            permissionService.checkCurrentStatuses()
            if permissionService.hasPhotosAccess && viewModel.groups.isEmpty {
                await viewModel.scan()
            }
        }
        .onAppear {
            permissionService.checkCurrentStatuses()
        }
    }
}
