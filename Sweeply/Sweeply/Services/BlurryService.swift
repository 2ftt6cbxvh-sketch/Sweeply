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
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isSynchronous = false
            options.isNetworkAccessAllowed = false
            
            // Analyze at 300x300 for crisp edge measurement
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image, let cgImage = image.cgImage else {
                    continuation.resume(returning: false)
                    return
                }
                
                let (isBlurry, _) = self.analyzeClarity(cgImage: cgImage)
                continuation.resume(returning: isBlurry)
            }
        }
    }
    
    public func analyzeClarity(cgImage: CGImage) -> (isBlurry: Bool, edgeScore: Double) {
        let ciImage = CIImage(cgImage: cgImage)
        
        // 1. Edge detection filter (Sobel/Gradient magnitude)
        guard let edgeFilter = CIFilter(name: "CIEdges") else {
            return (false, 50.0)
        }
        edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(3.5, forKey: "inputIntensity")
        
        guard let edgeOutput = edgeFilter.outputImage else {
            return (false, 50.0)
        }
        
        // 2. Measure overall edge energy across the image
        guard let avgFilter = CIFilter(name: "CIAreaAverage") else {
            return (false, 50.0)
        }
        avgFilter.setValue(edgeOutput, forKey: kCIInputImageKey)
        avgFilter.setValue(CIVector(cgRect: edgeOutput.extent), forKey: kCIInputExtentKey)
        
        guard let avgOutput = avgFilter.outputImage else {
            return (false, 50.0)
        }
        
        var edgeBitmap = [UInt8](repeating: 0, count: 4)
        context.render(avgOutput,
                       toBitmap: &edgeBitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let edgeScore = Double(edgeBitmap[0] + edgeBitmap[1] + edgeBitmap[2]) / 3.0
        
        // 3. Measure average brightness to identify accidental black pocket/bag shots
        var brightBitmap = [UInt8](repeating: 0, count: 4)
        if let brightAvg = CIFilter(name: "CIAreaAverage") {
            brightAvg.setValue(ciImage, forKey: kCIInputImageKey)
            brightAvg.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
            if let bOut = brightAvg.outputImage {
                context.render(bOut,
                               toBitmap: &brightBitmap,
                               rowBytes: 4,
                               bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                               format: .RGBA8,
                               colorSpace: CGColorSpaceCreateDeviceRGB())
            }
        }
        let brightness = Double(brightBitmap[0] + brightBitmap[1] + brightBitmap[2]) / 3.0
        
        // True blur occurs when edge score is very low (< 3.0). Clear photos are typically 10.0 - 60.0.
        // Accidental dark pocket shot has brightness < 5.0.
        let isPocketShot = brightness < 5.0
        let isDefiniteBlur = edgeScore < 2.8
        
        return (isPocketShot || isDefiniteBlur, edgeScore)
    }
}
