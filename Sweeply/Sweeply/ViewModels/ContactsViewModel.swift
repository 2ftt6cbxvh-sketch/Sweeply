import Foundation
import Contacts
import SwiftUI
import Combine

public enum ContactTab: String, CaseIterable, Identifiable {
    case duplicates = "Duplicates"
    case incomplete = "Incomplete"
    
    public var id: String { rawValue }
}

@MainActor
public final class ContactsViewModel: ObservableObject {
    @Published public var selectedTab: ContactTab = .duplicates
    @Published public var groups: [ContactDuplicateGroup] = []
    @Published public var incompleteContacts: [ContactItem] = []
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
            let incomplete = contactService.findIncompleteContacts(from: contacts)
            self.groups = duplicateGroups
            self.incompleteContacts = incomplete
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
            HapticService.shared.notification(.success)
        } catch {
            feedbackMessage = "Failed to merge: \(error.localizedDescription)"
            HapticService.shared.notification(.error)
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
            HapticService.shared.notification(.success)
            UndoService.shared.recordClean(title: "Merged duplicate contacts", count: idsToDelete.count, bytes: 0)
        } catch {
            feedbackMessage = "Failed to delete: \(error.localizedDescription)"
            HapticService.shared.notification(.error)
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
        HapticService.shared.notification(.success)
        isMerging = false
    }
    
    public func purgeIncompleteContacts() async {
        isMerging = true
        let ids = Set(incompleteContacts.map(\.id))
        do {
            try await contactService.deleteContacts(ids: ids)
            let count = incompleteContacts.count
            incompleteContacts.removeAll()
            feedbackMessage = "Purged \(count) incomplete contact(s)!"
            HapticService.shared.notification(.success)
            UndoService.shared.recordClean(title: "Purged incomplete contacts", count: count, bytes: 0)
        } catch {
            feedbackMessage = "Failed to purge: \(error.localizedDescription)"
            HapticService.shared.notification(.error)
        }
        isMerging = false
    }
    
    public func createDemoContacts() async {
        isLoading = true
        try? await contactService.createSampleDuplicateContacts()
        try? await contactService.createSampleIncompleteContacts()
        await load()
        HapticService.shared.impact(.medium)
        isLoading = false
    }
}
