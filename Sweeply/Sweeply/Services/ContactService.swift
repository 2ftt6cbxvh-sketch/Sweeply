import Foundation
import Contacts

public final class ContactService {
    public static let shared = ContactService()
    private let contactStore = CNContactStore()
    
    private init() {}
    
    public func fetchAllContacts() async throws -> [ContactItem] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        var contacts: [ContactItem] = []
        
        try contactStore.enumerateContacts(with: request) { cnContact, _ in
            contacts.append(ContactItem(contact: cnContact))
        }
        
        return contacts
    }
    
    public func findDuplicateGroups(from contacts: [ContactItem]) -> [ContactDuplicateGroup] {
        var groups: [ContactDuplicateGroup] = []
        var processedContactIds = Set<String>()
        
        // 1. Group by identical normalized phone number
        var phoneMap: [String: [ContactItem]] = [:]
        for contact in contacts {
            for phone in contact.phoneNumbers {
                let normalized = ContactDuplicateGroup.normalize(phone: phone)
                // Skip very short numbers (< 6 digits)
                guard normalized.count >= 6 else { continue }
                phoneMap[normalized, default: []].append(contact)
            }
        }
        
        for (phone, matched) in phoneMap {
            // Deduplicate contacts within list (in case one contact had duplicate numbers)
            let unique = Array(Dictionary(grouping: matched, by: \.id).values.compactMap(\.first))
            if unique.count > 1 {
                let ids = unique.map(\.id)
                // If not already completely contained
                if !ids.allSatisfy({ processedContactIds.contains($0) }) {
                    groups.append(ContactDuplicateGroup(
                        contacts: unique,
                        matchReason: .phoneNumber,
                        matchedValue: phone
                    ))
                    ids.forEach { processedContactIds.insert($0) }
                }
            }
        }
        
        // 2. Group by identical email
        var emailMap: [String: [ContactItem]] = [:]
        for contact in contacts {
            for email in contact.emailAddresses {
                let normalized = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalized.isEmpty else { continue }
                emailMap[normalized, default: []].append(contact)
            }
        }
        
        for (email, matched) in emailMap {
            let unique = Array(Dictionary(grouping: matched, by: \.id).values.compactMap(\.first))
            if unique.count > 1 {
                let ids = unique.map(\.id)
                if !ids.allSatisfy({ processedContactIds.contains($0) }) {
                    groups.append(ContactDuplicateGroup(
                        contacts: unique,
                        matchReason: .email,
                        matchedValue: email
                    ))
                    ids.forEach { processedContactIds.insert($0) }
                }
            }
        }
        
        // 3. Group by identical name
        var nameMap: [String: [ContactItem]] = [:]
        for contact in contacts {
            let name = contact.fullName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard name.count > 2 && name != "unnamed contact" else { continue }
            nameMap[name, default: []].append(contact)
        }
        
        for (name, matched) in nameMap {
            let unique = Array(Dictionary(grouping: matched, by: \.id).values.compactMap(\.first))
            if unique.count > 1 {
                let ids = unique.map(\.id)
                if !ids.allSatisfy({ processedContactIds.contains($0) }) {
                    groups.append(ContactDuplicateGroup(
                        contacts: unique,
                        matchReason: .name,
                        matchedValue: matched.first?.fullName ?? name
                    ))
                    ids.forEach { processedContactIds.insert($0) }
                }
            }
        }
        
        return groups
    }
    
    public func mergeDuplicateGroup(_ group: ContactDuplicateGroup) async throws {
        guard let primary = group.primaryContact else { return }
        
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor
        ]
        
        let saveRequest = CNSaveRequest()
        
        // Fetch mutable primary contact
        let primaryCN = try contactStore.unifiedContact(withIdentifier: primary.id, keysToFetch: keysToFetch)
        guard let mutablePrimary = primaryCN.mutableCopy() as? CNMutableContact else { return }
        
        // Consolidate phone numbers
        var existingPhoneNumbers = mutablePrimary.phoneNumbers.map { ContactDuplicateGroup.normalize(phone: $0.value.stringValue) }
        var updatedPhones = mutablePrimary.phoneNumbers
        
        for phone in group.consolidatedPhoneNumbers {
            let normalized = ContactDuplicateGroup.normalize(phone: phone)
            if !existingPhoneNumbers.contains(normalized) {
                existingPhoneNumbers.append(normalized)
                updatedPhones.append(CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone)))
            }
        }
        mutablePrimary.phoneNumbers = updatedPhones
        
        // Consolidate emails
        var existingEmails = mutablePrimary.emailAddresses.map { ($0.value as String).lowercased() }
        var updatedEmails = mutablePrimary.emailAddresses
        
        for email in group.consolidatedEmailAddresses {
            let lower = email.lowercased()
            if !existingEmails.contains(lower) {
                existingEmails.append(lower)
                updatedEmails.append(CNLabeledValue(label: CNLabelHome, value: email as NSString))
            }
        }
        mutablePrimary.emailAddresses = updatedEmails
        
        // Save the updated primary contact
        saveRequest.update(mutablePrimary)
        
        // Delete the duplicate contacts
        for contact in group.contacts where contact.id != primary.id {
            if let cnToDelete = try? contactStore.unifiedContact(withIdentifier: contact.id, keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor]) {
                if let mutableToDelete = cnToDelete.mutableCopy() as? CNMutableContact {
                    saveRequest.delete(mutableToDelete)
                }
            }
        }
        
        try contactStore.execute(saveRequest)
    }
    
    public func deleteContacts(ids: Set<String>) async throws {
        guard !ids.isEmpty else { return }
        let saveRequest = CNSaveRequest()
        
        for id in ids {
            if let contact = try? contactStore.unifiedContact(withIdentifier: id, keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor]) {
                if let mutable = contact.mutableCopy() as? CNMutableContact {
                    saveRequest.delete(mutable)
                }
            }
        }
        
        try contactStore.execute(saveRequest)
    }
}
