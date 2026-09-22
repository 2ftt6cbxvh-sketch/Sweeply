import SwiftUI

public struct ContactMergeDetailView: View {
    public let group: ContactDuplicateGroup
    @ObservedObject public var viewModel: ContactsViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(group: ContactDuplicateGroup, viewModel: ContactsViewModel) {
        self.group = group
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.green)
                        }
                        
                        Text(group.primaryContact?.fullName ?? "Duplicate Group")
                            .font(.title2.weight(.bold))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                            Text("Reason: \(group.matchReason.rawValue) (\(group.matchedValue))")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 10)
                    
                    // Merged Result Preview Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.green)
                            Text("PROPOSED MERGED CONTACT")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.primaryContact?.fullName ?? "")
                                .font(.headline)
                            
                            if !group.consolidatedPhoneNumbers.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Phone Numbers:")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    ForEach(group.consolidatedPhoneNumbers, id: \.self) { phone in
                                        HStack {
                                            Image(systemName: "phone.fill")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                            Text(phone)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                            
                            if !group.consolidatedEmailAddresses.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Email Addresses:")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    ForEach(group.consolidatedEmailAddresses, id: \.self) { email in
                                        HStack {
                                            Image(systemName: "envelope.fill")
                                                .font(.caption)
                                                .foregroundStyle(.blue)
                                            Text(email)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Original Contacts List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ORIGINAL DUPLICATES (\(group.contacts.count))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(group.contacts) { contact in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(contact.initials)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.fullName)
                                            .font(.subheadline.weight(.semibold))
                                        if let firstPhone = contact.phoneNumbers.first {
                                            Text(firstPhone)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(12)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await viewModel.mergeGroup(group)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.merge")
                                Text("Merge into 1 Contact")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(14)
                        }
                        
                        Button {
                            Task {
                                await viewModel.deleteDuplicatesInGroup(group)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Duplicate Copies")
                                    .font(.headline)
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
