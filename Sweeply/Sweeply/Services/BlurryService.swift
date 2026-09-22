import Foundation
import Photos
import CoreImage
import UIKit

public final class BlurryService {
    public static let shared = BlurryService()
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    
    private init() {}
    
    public func detectBlurryPhotos(assets: [MediaAsset], progressHandler: ((Double) -> Void)? = nil) async -> [MediaAsset] {
        var blurryAssets: [MediaAsset] = []
        let total = max(assets.count, 1)
        
        for (index, asset) in assets.enumerated() {
            let isBlurry = await isImageBlurry(asset: asset.phAsset)
            if isBlurry {
                blurryAssets.append(asset)
            }
            progressHandler?(Double(index + 1) / Double(total))
        }
        
        return blurryAssets
    }
    
    private func isImageBlurry(asset: PHAsset) async -> Bool {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = false
            options.isNetworkAccessAllowed = false
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 250, height: 250),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image, let cgImage = image.cgImage else {
                    continuation.resume(returning: false)
                    return
                }
                
                let score = self.calculateLaplacianVariance(cgImage: cgImage)
                // Threshold: score < 8.0 indicates heavy blur
                continuation.resume(returning: score < 8.0)
            }
        }
    }
    
    private func calculateLaplacianVariance(cgImage: CGImage) -> Double {
        let ciImage = CIImage(cgImage: cgImage)
        
        // 3x3 Laplacian filter kernel
        let weights: [CGFloat] = [
            0,  1, 0,
            1, -4, 1,
            0,  1, 0
        ]
        
        guard let filter = CIFilter(name: "CIConvolution3X3") else { return 50.0 }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(values: weights, count: 9), forKey: "inputWeights")
        filter.setValue(0.0, forKey: "inputBias")
        
        guard let outputImage = filter.outputImage else { return 50.0 }
        
        // Measure area average / variance
        guard let extentFilter = CIFilter(name: "CIAreaAverage") else { return 50.0 }
        extentFilter.setValue(outputImage, forKey: kCIInputImageKey)
        extentFilter.setValue(CIVector(cgRect: outputImage.extent), forKey: kCIInputExtentKey)
        
        guard let extentImage = extentFilter.outputImage else { return 50.0 }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(extentImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let intensity = Double(bitmap[0] + bitmap[1] + bitmap[2]) / 3.0
        return intensity
    }
}
