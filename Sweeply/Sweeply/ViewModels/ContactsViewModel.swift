import Foundation
import Contacts
import SwiftUI
import Combine

@MainActor
public final class ContactsViewModel: ObservableObject {
    @Published public var groups: [ContactDuplicateGroup] = []
    @Published public var isLoading: Bool = false
    @Published public var selectedGroupForDetail: ContactDuplicateGroup? = nil
    @Published public var isMerging: Bool = false
    @Published public var feedbackMessage: String? = nil
    
    private let contactService = ContactService.shared
    
    public init() {}
    
    public var totalDuplicatesCount: Int {
        groups.reduce(0) { $0 + max(0, $1.contacts.count - 1) }
    }
    
    public func load() async {
        isLoading = true
        do {
            let contacts = try await contactService.fetchAllContacts()
            let duplicateGroups = contactService.findDuplicateGroups(from: contacts)
            self.groups = duplicateGroups
        } catch {
            self.feedbackMessage = "Error loading contacts: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    public func mergeGroup(_ group: ContactDuplicateGroup) async {
        isMerging = true
        do {
            try await contactService.mergeDuplicateGroup(group)
            groups.removeAll { $0.id == group.id }
            feedbackMessage = "Successfully merged contacts into one!"
        } catch {
            feedbackMessage = "Failed to merge: \(error.localizedDescription)"
        }
        isMerging = false
    }
    
    public func deleteDuplicatesInGroup(_ group: ContactDuplicateGroup) async {
        isMerging = true
        guard let primary = group.primaryContact else { return }
        let idsToDelete = Set(group.contacts.filter { $0.id != primary.id }.map(\.id))
        do {
            try await contactService.deleteContacts(ids: idsToDelete)
            groups.removeAll { $0.id == group.id }
            feedbackMessage = "Deleted \(idsToDelete.count) duplicate contact(s)"
        } catch {
            feedbackMessage = "Failed to delete: \(error.localizedDescription)"
        }
        isMerging = false
    }
    
    public func mergeAllGroups() async {
        isMerging = true
        var mergedCount = 0
        for group in groups {
            do {
                try await contactService.mergeDuplicateGroup(group)
                mergedCount += 1
            } catch {
                continue
            }
        }
        await load()
        feedbackMessage = "Cleaned and merged \(mergedCount) contact group(s)!"
        isMerging = false
    }
}
