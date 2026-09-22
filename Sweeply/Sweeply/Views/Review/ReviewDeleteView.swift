import SwiftUI
import Photos

public struct ReviewDeleteView: View {
    @StateObject private var viewModel: ReviewDeleteViewModel
    @Environment(\.dismiss) private var dismiss
    public let onCleanFinished: (Int64) -> Void
    
    public init(batch: CleanBatch, onCleanFinished: @escaping (Int64) -> Void) {
        self._viewModel = StateObject(wrappedValue: ReviewDeleteViewModel(batch: batch))
        self.onCleanFinished = onCleanFinished
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary Banner
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.12))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "trash.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.red)
                            }
                            
                            Text("Review Before Clean")
                                .font(.title2.weight(.bold))
                            
                            Text("Ready to free \(viewModel.batch.formattedSizeToFree)")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            
                            // Safety Guarantee Notice
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.green)
                                    .font(.subheadline)
                                
                                Text("Nothing is permanently erased immediately. Photos are moved to iOS's \"Recently Deleted\" album where you have 30 days to restore them.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.top, 12)
                        
                        // Error message banner if any
                        if let error = viewModel.deletionError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                        
                        // Itemized List Header
                        HStack {
                            Text("ITEMS TO REMOVE (\(viewModel.batch.totalItemsCount))")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Itemized Assets List
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.batch.assets) { asset in
                                HStack(spacing: 12) {
                                    ThumbnailImageView(asset: asset.phAsset, targetSize: CGSize(width: 120, height: 120))
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(8)
                                        .clipped()
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(asset.formattedSize)
                                            .font(.subheadline.weight(.semibold))
                                        Text(asset.formattedDate)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Remove from deletion queue button
                                    Button {
                                        withAnimation {
                                            viewModel.removeItem(assetId: asset.id)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.gray.opacity(0.5))
                                    }
                                }
                                .padding(10)
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                            .frame(height: 100)
                    }
                }
                
                // Bottom Sticky Approval Button
                VStack {
                    Button {
                        Task {
                            let freed = viewModel.batch.totalBytesToFree
                            let success = await viewModel.executeClean()
                            if success {
                                dismiss()
                                onCleanFinished(freed)
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isDeleting {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 6)
                            } else {
                                Image(systemName: "trash.fill")
                            }
                            Text(viewModel.isDeleting ? "Cleaning..." : "Confirm & Clean \(viewModel.batch.totalItemsCount) Items")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(viewModel.batch.totalItemsCount == 0 ? Color.gray : Color.red)
                        .cornerRadius(16)
                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(viewModel.batch.totalItemsCount == 0 || viewModel.isDeleting)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .background(
                    LinearGradient(
                        colors: [Color(uiColor: .systemGroupedBackground).opacity(0), Color(uiColor: .systemGroupedBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
