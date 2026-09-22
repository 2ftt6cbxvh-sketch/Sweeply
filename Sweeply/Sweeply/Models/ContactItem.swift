import Foundation
import Contacts

public struct ContactItem: Identifiable, Hashable {
    public let id: String
    public let givenName: String
    public let familyName: String
    public let phoneNumbers: [String]
    public let emailAddresses: [String]
    public let thumbnailImageData: Data?
    public let organizationName: String
    
    public init(contact: CNContact) {
        self.id = contact.identifier
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        self.organizationName = contact.organizationName
        self.phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
        self.emailAddresses = contact.emailAddresses.map { $0.value as String }
        self.thumbnailImageData = contact.thumbnailImageData
    }
    
    public init(id: String, givenName: String, familyName: String, phoneNumbers: [String], emailAddresses: [String], organizationName: String = "", thumbnailImageData: Data? = nil) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
        self.organizationName = organizationName
        self.thumbnailImageData = thumbnailImageData
    }
    
    public var fullName: String {
        let trimmedGiven = givenName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFamily = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedGiven.isEmpty && !trimmedFamily.isEmpty {
            return "\(trimmedGiven) \(trimmedFamily)"
        } else if !trimmedGiven.isEmpty {
            return trimmedGiven
        } else if !trimmedFamily.isEmpty {
            return trimmedFamily
        } else if !organizationName.isEmpty {
            return organizationName
        } else if let firstPhone = phoneNumbers.first {
            return firstPhone
        } else if let firstEmail = emailAddresses.first {
            return firstEmail
        } else {
            return "Unnamed Contact"
        }
    }
    
    public var initials: String {
        let first = givenName.first.map(String.init) ?? ""
        let last = familyName.first.map(String.init) ?? ""
        let combined = "\(first)\(last)"
        return combined.isEmpty ? "?" : combined.uppercased()
    }
}
