import XCTest
@testable import Sweeply

@MainActor
final class SwipeCleanViewModelTests: XCTestCase {
    
    func testInitialDeckState() {
        let vm = SwipeCleanViewModel()
        XCTAssertTrue(vm.deck.isEmpty)
        XCTAssertTrue(vm.keptAssets.isEmpty)
        XCTAssertTrue(vm.trashedAssets.isEmpty)
        XCTAssertNil(vm.currentAsset)
        XCTAssertEqual(vm.totalTrashedBytes, 0)
    }
    
    func testSwipeLeftAddsToTrashedAssets() {
        let vm = SwipeCleanViewModel()
        let asset1 = MediaAsset(id: "photo-1", fileSize: 3_000_000)
        let asset2 = MediaAsset(id: "photo-2", fileSize: 4_500_000)
        vm.deck = [asset1, asset2]
        
        XCTAssertEqual(vm.currentAsset?.id, "photo-1")
        
        // Swipe Left (Clean)
        vm.swipeLeft()
        
        XCTAssertEqual(vm.deck.count, 1)
        XCTAssertEqual(vm.currentAsset?.id, "photo-2")
        XCTAssertEqual(vm.trashedAssets.count, 1)
        XCTAssertEqual(vm.trashedAssets.first?.id, "photo-1")
        XCTAssertEqual(vm.totalTrashedBytes, 3_000_000)
        XCTAssertTrue(vm.keptAssets.isEmpty)
    }
    
    func testSwipeRightAddsToKeptAssets() {
        let vm = SwipeCleanViewModel()
        let asset1 = MediaAsset(id: "photo-1", fileSize: 2_000_000)
        let asset2 = MediaAsset(id: "photo-2", fileSize: 5_000_000)
        vm.deck = [asset1, asset2]
        
        // Swipe Right (Keep)
        vm.swipeRight()
        
        XCTAssertEqual(vm.deck.count, 1)
        XCTAssertEqual(vm.currentAsset?.id, "photo-2")
        XCTAssertEqual(vm.keptAssets.count, 1)
        XCTAssertEqual(vm.keptAssets.first?.id, "photo-1")
        XCTAssertTrue(vm.trashedAssets.isEmpty)
        XCTAssertEqual(vm.totalTrashedBytes, 0)
    }
    
    func testUndoRestoresLastAction() {
        let vm = SwipeCleanViewModel()
        let asset1 = MediaAsset(id: "photo-1", fileSize: 1_000_000)
        let asset2 = MediaAsset(id: "photo-2", fileSize: 2_000_000)
        vm.deck = [asset1, asset2]
        
        // Swipe left on asset1
        vm.swipeLeft()
        XCTAssertEqual(vm.deck.count, 1)
        XCTAssertEqual(vm.trashedAssets.count, 1)
        
        // Undo
        vm.undo()
        XCTAssertEqual(vm.deck.count, 2)
        XCTAssertEqual(vm.currentAsset?.id, "photo-1")
        XCTAssertTrue(vm.trashedAssets.isEmpty)
    }
    
    func testPrepareCleanBatch() {
        let vm = SwipeCleanViewModel()
        let asset1 = MediaAsset(id: "photo-1", fileSize: 10_000_000)
        let asset2 = MediaAsset(id: "photo-2", fileSize: 15_000_000)
        vm.deck = [asset1, asset2]
        
        XCTAssertNil(vm.prepareCleanBatch())
        
        vm.swipeLeft()
        vm.swipeLeft()
        
        let batch = vm.prepareCleanBatch()
        XCTAssertNotNil(batch)
        XCTAssertEqual(batch?.totalItemsCount, 2)
        XCTAssertEqual(batch?.totalBytesToFree, 25_000_000)
    }
}
