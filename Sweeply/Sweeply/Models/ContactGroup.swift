import Foundation
import Contacts

public enum ContactMatchReason: String, CaseIterable, Codable {
    case phoneNumber = "Identical Phone Number"
    case email = "Identical Email"
    case name = "Identical Name"
    case multiple = "Name & Details Match"
}

public struct ContactDuplicateGroup: Identifiable, Hashable {
    public let id: UUID
    public var contacts: [ContactItem]
    public let matchReason: ContactMatchReason
    public let matchedValue: String
    public var selectedIds: Set<String>
    
    public init(id: UUID = UUID(), contacts: [ContactItem], matchReason: ContactMatchReason, matchedValue: String) {
        self.id = id
        self.contacts = contacts
        self.matchReason = matchReason
        self.matchedValue = matchedValue
        // By default, select all except the first one for action/deletion
        if contacts.count > 1 {
            self.selectedIds = Set(contacts.dropFirst().map(\.id))
        } else {
            self.selectedIds = []
        }
    }
    
    public var primaryContact: ContactItem? {
        // Choose the contact with the most information
        contacts.max { a, b in
            let aScore = a.phoneNumbers.count + a.emailAddresses.count + (a.thumbnailImageData != nil ? 2 : 0)
            let bScore = b.phoneNumbers.count + b.emailAddresses.count + (b.thumbnailImageData != nil ? 2 : 0)
            return aScore < bScore
        } ?? contacts.first
    }
    
    public var consolidatedPhoneNumbers: [String] {
        var set = Set<String>()
        var result: [String] = []
        for contact in contacts {
            for phone in contact.phoneNumbers {
                let normalized = ContactDuplicateGroup.normalize(phone: phone)
                if !set.contains(normalized) {
                    set.insert(normalized)
                    result.append(phone)
                }
            }
        }
        return result
    }
    
    public var consolidatedEmailAddresses: [String] {
        var set = Set<String>()
        var result: [String] = []
        for contact in contacts {
            for email in contact.emailAddresses {
                let lower = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if !set.contains(lower) {
                    set.insert(lower)
                    result.append(email)
                }
            }
        }
        return result
    }
    
    public static func normalize(phone: String) -> String {
        var digits = phone.filter { "0123456789".contains($0) }
        if digits.hasPrefix("1") && digits.count >= 8 {
            digits = String(digits.dropFirst())
        }
        if digits.count > 10 {
            return String(digits.suffix(10))
        }
        return digits
    }
}
