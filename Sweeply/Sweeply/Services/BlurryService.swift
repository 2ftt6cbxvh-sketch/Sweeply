import Foundation
import Photos
import CoreGraphics
import UIKit

public final class BlurryService {
    public static let shared = BlurryService()
    
    private init() {}
    
    public func detectBlurryPhotos(assets: [MediaAsset], progressHandler: ((Double) -> Void)? = nil) async -> [MediaAsset] {
        var blurryAssets: [MediaAsset] = []
        let total = max(assets.count, 1)
        
        for (index, asset) in assets.enumerated() {
            let isBlurry = await isImageBlurry(asset: asset.phAsset)
            if isBlurry {
                blurryAssets.append(asset)
            }
            if index % 5 == 0 || index == assets.count - 1 {
                progressHandler?(Double(index + 1) / Double(total))
            }
        }
        
        return blurryAssets
    }
    
    private func isImageBlurry(asset: PHAsset) async -> Bool {
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return false }
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = true
            options.isNetworkAccessAllowed = false
            
            var isBlurry = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 128, height: 128),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image, let cgImage = image.cgImage else {
                    return
                }
                let (blurry, _) = self.analyzeClarity(cgImage: cgImage)
                isBlurry = blurry
            }
            return isBlurry
        }.value
    }
    
    public func analyzeClarity(cgImage: CGImage) -> (isBlurry: Bool, edgeScore: Double) {
        let width = 64
        let height = 64
        guard cgImage.width > 0 && cgImage.height > 0 else {
            return (false, 50.0)
        }
        
        var pixels = [UInt8](repeating: 0, count: width * height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return (false, 50.0)
        }
        
        ctx.interpolationQuality = .medium
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 1. Calculate average brightness to detect accidental dark pocket/bag shots
        var totalBrightness: Double = 0
        for p in pixels {
            totalBrightness += Double(p)
        }
        let avgBrightness = totalBrightness / Double(pixels.count)
        
        // Dark pocket shots have brightness < 5.0 out of 255
        if avgBrightness < 5.0 {
            return (true, 0.0)
        }
        
        // 2. Laplacian convolution kernel:
        // [  0,  1,  0 ]
        // [  1, -4,  1 ]
        // [  0,  1,  0 ]
        var laplacianValues: [Double] = []
        laplacianValues.reserveCapacity((width - 2) * (height - 2))
        
        var sumLaplacian: Double = 0
        
        for y in 1..<(height - 1) {
            let rowOffset = y * width
            let prevRowOffset = (y - 1) * width
            let nextRowOffset = (y + 1) * width
            
            for x in 1..<(width - 1) {
                let center = Double(pixels[rowOffset + x])
                let top = Double(pixels[prevRowOffset + x])
                let bottom = Double(pixels[nextRowOffset + x])
                let left = Double(pixels[rowOffset + x - 1])
                let right = Double(pixels[rowOffset + x + 1])
                
                let lap = (top + bottom + left + right) - (4.0 * center)
                laplacianValues.append(lap)
                sumLaplacian += lap
            }
        }
        
        let count = Double(laplacianValues.count)
        guard count > 0 else { return (false, 50.0) }
        
        let meanLaplacian = sumLaplacian / count
        var varianceSum: Double = 0
        for val in laplacianValues {
            let diff = val - meanLaplacian
            varianceSum += diff * diff
        }
        let variance = varianceSum / count
        
        // Threshold: sharp photos have variance > 40.0; blurry / out-of-focus photos have variance < 14.0
        let isBlurry = variance < 14.0
        return (isBlurry, variance)
    }
}
