import XCTest
import CoreGraphics
@testable import Sweeply

final class BlurryServiceTests: XCTestCase {
    
    func testPitchBlackImageDetectedAsPocketShot() {
        let width = 64
        let height = 64
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 2, count: width * height) // Almost pitch black
        
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let cgImage = ctx.makeImage() else {
            XCTFail("Failed to create test CGImage")
            return
        }
        
        let (isBlurry, _) = BlurryService.shared.analyzeClarity(cgImage: cgImage)
        XCTAssertTrue(isBlurry, "Dark pocket shots must be detected as blurry/reclaimable")
    }
    
    func testFlatFeaturelessImageDetectedAsBlurry() {
        let width = 64
        let height = 64
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 128, count: width * height) // Uniform grey (no edges)
        
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let cgImage = ctx.makeImage() else {
            XCTFail("Failed to create test CGImage")
            return
        }
        
        let (isBlurry, score) = BlurryService.shared.analyzeClarity(cgImage: cgImage)
        XCTAssertTrue(isBlurry, "Flat textureless photos have zero edge variance")
        XCTAssertEqual(score, 0.0, accuracy: 0.001)
    }
    
    func testHighContrastSharpImageDetectedAsSharp() {
        let width = 64
        let height = 64
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 0, count: width * height)
        // Draw sharp checkerboard / high frequency pattern
        for y in 0..<height {
            for x in 0..<width {
                pixels[y * width + x] = ((x / 4) + (y / 4)) % 2 == 0 ? 255 : 0
            }
        }
        
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let cgImage = ctx.makeImage() else {
            XCTFail("Failed to create test CGImage")
            return
        }
        
        let (isBlurry, score) = BlurryService.shared.analyzeClarity(cgImage: cgImage)
        XCTAssertFalse(isBlurry, "High-frequency patterned/sharp photo should not be flagged as blurry")
        XCTAssertGreaterThan(score, 40.0)
    }
}
