import SwiftUI
import Photos

public struct ThumbnailImageView: View {
    public let asset: PHAsset
    public let targetSize: CGSize
    
    @State private var image: UIImage? = nil
    @State private var requestID: PHImageRequestID? = nil
    
    public init(asset: PHAsset, targetSize: CGSize = CGSize(width: 200, height: 200)) {
        self.asset = asset
        self.targetSize = targetSize
    }
    
    public var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
        }
        .clipped()
        .onAppear {
            loadImage()
        }
        .onChange(of: asset.localIdentifier) { _ in
            loadImage()
        }
        .onDisappear {
            cancelImageLoad()
        }
    }
    
    private func loadImage() {
        cancelImageLoad()
        self.image = nil
        requestID = PhotoService.shared.requestThumbnail(for: asset, targetSize: targetSize) { loadedImage in
            if let loadedImage = loadedImage {
                self.image = loadedImage
            }
        }
    }
    
    private func cancelImageLoad() {
        if let id = requestID {
            PHImageManager.default().cancelImageRequest(id)
            requestID = nil
        }
    }
}
