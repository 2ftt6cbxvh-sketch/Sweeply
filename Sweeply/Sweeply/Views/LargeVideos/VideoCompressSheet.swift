import SwiftUI
import Photos

public struct VideoCompressSheet: View {
    public let asset: MediaAsset
    @ObservedObject public var viewModel: LargeVideosViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(asset: MediaAsset, viewModel: LargeVideosViewModel) {
        self.asset = asset
        self.viewModel = viewModel
    }
    
    public var estimatedNewBytes: Int64 {
        Int64(Double(asset.fileSize) * viewModel.compressionQuality.estimatedCompressionRatio)
    }
    
    public var estimatedNewSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: estimatedNewBytes, countStyle: .file)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 6) {
                    Text("Compress Video")
                        .font(.title2.weight(.bold))
                    Text("Shrink file size while preserving high visual quality")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 10)
                
                // Video Preview Card
                ZStack {
                    ThumbnailImageView(asset: asset.phAsset, targetSize: CGSize(width: 400, height: 300))
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(18)
                        .clipped()
                    
                    // Duration badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(asset.formattedDuration)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(6)
                                .padding(10)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Size Comparison Badge (Like the reference app)
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Original")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(asset.formattedSize)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Compressed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(estimatedNewSizeFormatted)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                
                // Quality Segment Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compression Quality")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    Picker("Quality", selection: $viewModel.compressionQuality) {
                        ForEach(VideoCompressionQuality.allCases) { q in
                            Text(q.rawValue).tag(q)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Progress / Feedback
                if viewModel.isCompressing {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.compressionProgress)
                            .tint(.blue)
                        Text("Compressing... \(Int(viewModel.compressionProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                } else if let msg = viewModel.compressionSuccessMessage {
                    Text(msg)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action Button
                Button {
                    Task {
                        await viewModel.compressCurrentVideo()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                        Text(viewModel.isCompressing ? "Compressing..." : "Start Compress")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .disabled(viewModel.isCompressing)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
