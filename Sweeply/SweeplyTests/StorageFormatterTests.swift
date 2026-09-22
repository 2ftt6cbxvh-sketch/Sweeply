import XCTest
@testable import Sweeply

final class StorageFormatterTests: XCTestCase {
    
    func testStoragePercentages() {
        let breakdown = StorageBreakdown(
            totalDiskBytes: 100_000_000_000,
            freeDiskBytes: 40_000_000_000,
            usedDiskBytes: 60_000_000_000,
            similarPhotosBytes: 2_000_000_000,
            screenshotsBytes: 1_000_000_000,
            largeVideosBytes: 5_000_000_000
        )
        
        XCTAssertEqual(breakdown.usedPercentage, 0.60, accuracy: 0.01)
        XCTAssertEqual(breakdown.freePercentage, 0.40, accuracy: 0.01)
        XCTAssertEqual(breakdown.totalReclaimableBytes, 8_000_000_000)
    }
    
    func testCleanBatchCalculation() {
        let batch = CleanBatch(
            title: "Test Batch",
            category: .similarPhotos,
            assets: []
        )
        
        XCTAssertEqual(batch.totalItemsCount, 0)
        XCTAssertEqual(batch.totalBytesToFree, 0)
    }
}
