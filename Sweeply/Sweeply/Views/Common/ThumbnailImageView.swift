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
        // Instant synchronous cache pre-fill to eliminate blank flashes during scrolling
        if let cached = PhotoService.shared.getCachedThumbnail(for: asset.localIdentifier) {
            _image = State(initialValue: cached)
        }
    }
    
    public var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(uiColor: .secondarySystemBackground).opacity(0.7))
            }
        }
        .clipped()
        .onAppear {
            if image == nil {
                loadImage()
            }
        }
        .onChange(of: asset.localIdentifier) { _ in
            loadImage()
        }
        .onDisappear {
            cancelImageLoad()
        }
    }
    
    private func loadImage() {
        if let cached = PhotoService.shared.getCachedThumbnail(for: asset.localIdentifier) {
            self.image = cached
            return
        }
        cancelImageLoad()
        requestID = PhotoService.shared.requestThumbnail(for: asset, targetSize: targetSize) { loadedImage in
            if let loadedImage = loadedImage {
                self.image = loadedImage
            }
        }
    }
    
    private func cancelImageLoad() {
        if let id = requestID, id != 0 {
            PHImageManager.default().cancelImageRequest(id)
            requestID = nil
        }
    }
}
