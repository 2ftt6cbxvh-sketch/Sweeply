import XCTest
import Contacts
import Photos
@testable import Sweeply

@MainActor
final class StandoutFeaturesTests: XCTestCase {
    
    func testIncompleteContactDetection() {
        let contactService = ContactService.shared
        
        let validContact = ContactItem(
            id: "1",
            givenName: "Jane",
            familyName: "Doe",
            phoneNumbers: ["+15551234567"],
            emailAddresses: ["jane@example.com"],
            organizationName: ""
        )
        
        let noNameContact = ContactItem(
            id: "2",
            givenName: "",
            familyName: "",
            phoneNumbers: ["+15559876543"],
            emailAddresses: [],
            organizationName: ""
        )
        
        let noPhoneOrEmailContact = ContactItem(
            id: "3",
            givenName: "Ghost",
            familyName: "User",
            phoneNumbers: [],
            emailAddresses: [],
            organizationName: ""
        )
        
        let allContacts = [validContact, noNameContact, noPhoneOrEmailContact]
        let incomplete = contactService.findIncompleteContacts(from: allContacts)
        
        XCTAssertEqual(incomplete.count, 2)
        XCTAssertTrue(incomplete.contains(where: { $0.id == "2" }))
        XCTAssertTrue(incomplete.contains(where: { $0.id == "3" }))
        XCTAssertFalse(incomplete.contains(where: { $0.id == "1" }))
    }
    
    func testLivePhotoSavingsEstimation() {
        let dummyAsset = PHAsset()
        let totalSize: Int64 = 10 * 1024 * 1024 // 10 MB
        let item = LivePhotoItem(phAsset: dummyAsset, totalSize: totalSize)
        
        // Estimated still size is ~32% = 3.2 MB
        // Reclaimable should be ~68% = 6.8 MB
        XCTAssertGreaterThan(item.reclaimableBytes, 6 * 1024 * 1024)
        XCTAssertLessThan(item.reclaimableBytes, 8 * 1024 * 1024)
    }
    
    func testUndoServiceRecording() {
        let undoService = UndoService.shared
        undoService.clearLastAction()
        XCTAssertNil(undoService.lastCleanAction)
        
        undoService.recordClean(title: "Screenshots", count: 12, bytes: 45 * 1024 * 1024)
        XCTAssertNotNil(undoService.lastCleanAction)
        XCTAssertEqual(undoService.lastCleanAction?.title, "Screenshots")
        XCTAssertEqual(undoService.lastCleanAction?.itemCount, 12)
        XCTAssertEqual(undoService.lastCleanAction?.bytesFreed, 45 * 1024 * 1024)
        
        undoService.clearLastAction()
        XCTAssertNil(undoService.lastCleanAction)
    }
}
