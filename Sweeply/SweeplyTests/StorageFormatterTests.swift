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
    
    func testPercentageOfFilledStorage() {
        let breakdown = StorageBreakdown(
            totalDiskBytes: 100_000_000_000,
            freeDiskBytes: 40_000_000_000,
            usedDiskBytes: 60_000_000_000
        )
        
        // 6 GB out of 60 GB used = 10.0%
        let pct = breakdown.percentageOfFilledStorage(bytes: 6_000_000_000)
        XCTAssertEqual(pct, 10.0, accuracy: 0.01)
        
        let formatted = breakdown.formattedPercentageOfFilledStorage(bytes: 6_000_000_000)
        XCTAssertEqual(formatted, "10.0% of filled disk")
        
        // 0 bytes test
        XCTAssertEqual(breakdown.percentageOfFilledStorage(bytes: 0), 0.0)
        XCTAssertEqual(breakdown.formattedPercentageOfFilledStorage(bytes: 0), "0% of filled disk")
    }
    
    func testMediaSortOrder() {
        XCTAssertEqual(MediaSortOrder.allCases.count, 4)
        XCTAssertEqual(MediaSortOrder.newest.shortLabel, "Newest")
        XCTAssertEqual(MediaSortOrder.oldest.shortLabel, "Oldest")
        XCTAssertEqual(MediaSortOrder.sizeDescending.shortLabel, "Largest")
        XCTAssertEqual(MediaSortOrder.sizeAscending.shortLabel, "Smallest")
    }
}
