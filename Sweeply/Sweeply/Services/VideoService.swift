import Foundation
import Photos
import AVFoundation

public enum VideoCompressionQuality: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    public var id: String { rawValue }
    
    public var presetName: String {
        switch self {
        case .low: return AVAssetExportPreset640x480
        case .medium: return AVAssetExportPreset1280x720
        case .high: return AVAssetExportPreset1920x1080
        }
    }
    
    public var estimatedCompressionRatio: Double {
        switch self {
        case .low: return 0.15   // ~85% smaller
        case .medium: return 0.35 // ~65% smaller
        case .high: return 0.60  // ~40% smaller
        }
    }
}

public final class VideoService {
    public static let shared = VideoService()
    
    private init() {}
    
    public func fetchAVAsset(for phAsset: PHAsset) async -> AVAsset? {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { asset, _, _ in
                continuation.resume(returning: asset)
            }
        }
    }
    
    public func compressVideo(
        phAsset: PHAsset,
        quality: VideoCompressionQuality,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> URL {
        guard let avAsset = await fetchAVAsset(for: phAsset) else {
            throw NSError(domain: "SweeplyVideo", code: 404, userInfo: [NSLocalizedDescriptionKey: "Failed to load video source"])
        }
        
        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: quality.presetName) else {
            throw NSError(domain: "SweeplyVideo", code: 500, userInfo: [NSLocalizedDescriptionKey: "Export session not supported for preset"])
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        exportSession.outputURL = tempURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        return try await withCheckedThrowingContinuation { continuation in
            let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                progressHandler?(Double(exportSession.progress))
            }
            
            exportSession.exportAsynchronously {
                timer.invalidate()
                switch exportSession.status {
                case .completed:
                    progressHandler?(1.0)
                    continuation.resume(returning: tempURL)
                case .failed:
                    continuation.resume(throwing: exportSession.error ?? NSError(domain: "SweeplyVideo", code: 500, userInfo: [NSLocalizedDescriptionKey: "Video compression failed"]))
                case .cancelled:
                    continuation.resume(throwing: NSError(domain: "SweeplyVideo", code: 499, userInfo: [NSLocalizedDescriptionKey: "Video compression was cancelled"]))
                default:
                    continuation.resume(throwing: NSError(domain: "SweeplyVideo", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected export state"]))
                }
            }
        }
    }
    
    public func saveVideoToLibrary(url: URL) async throws -> PHAsset? {
        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            placeholder = request?.placeholderForCreatedAsset
        }
        guard let id = placeholder?.localIdentifier else { return nil }
        return PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
    }
}
