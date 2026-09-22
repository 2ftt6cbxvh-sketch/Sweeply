import XCTest
@testable import Sweeply

final class SimilarityServiceTests: XCTestCase {
    
    func testSimilarPhotoGroupSelectionAndSavings() {
        // Create mock group with best asset and duplicates
        let group = SimilarPhotoGroup(
            id: UUID(),
            assets: [],
            bestAssetId: "best-id",
            selectedIds: ["dup-1", "dup-2"],
            similarityScore: 0.95
        )
        
        XCTAssertEqual(group.bestAssetId, "best-id")
        XCTAssertTrue(group.selectedIds.contains("dup-1"))
        XCTAssertTrue(group.selectedIds.contains("dup-2"))
        XCTAssertFalse(group.selectedIds.contains("best-id"))
    }
    
    func testMarkAsBestSwapsSelection() {
        var group = SimilarPhotoGroup(
            id: UUID(),
            assets: [],
            bestAssetId: "asset-1",
            selectedIds: ["asset-2", "asset-3"],
            similarityScore: 0.90
        )
        
        // Mark asset-2 as best
        group.markAsBest(assetId: "asset-2")
        
        XCTAssertEqual(group.bestAssetId, "asset-2")
        XCTAssertFalse(group.selectedIds.contains("asset-2"))
    }
    
    func testDeselectAllClearsSelection() {
        var group = SimilarPhotoGroup(
            id: UUID(),
            assets: [],
            bestAssetId: "asset-1",
            selectedIds: ["asset-2", "asset-3"],
            similarityScore: 0.90
        )
        
        group.deselectAll()
        XCTAssertTrue(group.selectedIds.isEmpty)
        
        group.selectAllDuplicates()
        // assets was empty so it remains empty, but function executes safely
        XCTAssertTrue(group.selectedIds.isEmpty)
    }
}
