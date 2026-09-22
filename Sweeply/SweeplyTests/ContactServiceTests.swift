import XCTest
@testable import Sweeply

final class ContactServiceTests: XCTestCase {
    
    func testPhoneNumberNormalization() {
        let phone1 = "+1 (555) 123-4567"
        let phone2 = "1-555-123-4567"
        let phone3 = "555 123 4567"
        
        let norm1 = ContactDuplicateGroup.normalize(phone: phone1)
        let norm2 = ContactDuplicateGroup.normalize(phone: phone2)
        let norm3 = ContactDuplicateGroup.normalize(phone: phone3)
        
        XCTAssertEqual(norm1, "5551234567")
        XCTAssertEqual(norm2, "5551234567")
        XCTAssertEqual(norm3, "5551234567")
    }
    
    func testContactGroupingByPhoneNumber() {
        let contact1 = ContactItem(
            id: "c1",
            givenName: "John",
            familyName: "Appleseed",
            phoneNumbers: ["+1 555-0100"],
            emailAddresses: []
        )
        
        let contact2 = ContactItem(
            id: "c2",
            givenName: "Johnny",
            familyName: "Appleseed",
            phoneNumbers: ["(555) 0100"],
            emailAddresses: []
        )
        
        let groups = ContactService.shared.findDuplicateGroups(from: [contact1, contact2])
        XCTAssertFalse(groups.isEmpty)
        XCTAssertEqual(groups.first?.matchReason, .phoneNumber)
        XCTAssertEqual(groups.first?.contacts.count, 2)
    }
    
    func testContactGroupingByEmail() {
        let contact1 = ContactItem(
            id: "c1",
            givenName: "Alice",
            familyName: "Smith",
            phoneNumbers: [],
            emailAddresses: ["alice.smith@example.com"]
        )
        
        let contact2 = ContactItem(
            id: "c2",
            givenName: "Alice S.",
            familyName: "Smith",
            phoneNumbers: [],
            emailAddresses: ["ALICE.SMITH@EXAMPLE.COM"]
        )
        
        let groups = ContactService.shared.findDuplicateGroups(from: [contact1, contact2])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.matchReason, .email)
    }
    
    func testContactConsolidation() {
        let contact1 = ContactItem(
            id: "c1",
            givenName: "Alice",
            familyName: "Smith",
            phoneNumbers: ["+1 555-0101"],
            emailAddresses: ["alice@work.com"]
        )
        let contact2 = ContactItem(
            id: "c2",
            givenName: "Alice",
            familyName: "Smith",
            phoneNumbers: ["+1 555-0102"],
            emailAddresses: ["alice@home.com"]
        )
        
        let group = ContactDuplicateGroup(
            contacts: [contact1, contact2],
            matchReason: .name,
            matchedValue: "Alice Smith"
        )
        
        XCTAssertEqual(group.consolidatedPhoneNumbers.count, 2)
        XCTAssertEqual(group.consolidatedEmailAddresses.count, 2)
    }
}
