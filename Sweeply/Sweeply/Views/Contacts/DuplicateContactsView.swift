import SwiftUI

public struct DuplicateContactsView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @State private var showingPurgeConfirmation = false
    
    public init() {}
    
    public var body: some View {
        Group {
            if !permissionService.hasContactsAccess {
                PermissionNoticeView(
                    title: "Contacts Access Required",
                    message: "Sweeply scans contacts locally to find duplicates and incomplete cards.",
                    isDenied: permissionService.contactStatus == .denied
                ) {
                    if permissionService.contactStatus == .denied {
                        permissionService.openSettings()
                    } else {
                        Task {
                            let granted = await permissionService.requestContactsPermission()
                            if granted {
                                await viewModel.load()
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else if viewModel.isLoading {
                ProgressView("Analyzing address book...")
                    .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Segmented Tab Picker
                    Picker("Contact Categories", selection: $viewModel.selectedTab) {
                        Text("Duplicates (\(viewModel.groups.count))").tag(ContactTab.duplicates)
                        Text("Incomplete (\(viewModel.incompleteContacts.count))").tag(ContactTab.incomplete)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .onChange(of: viewModel.selectedTab) { _, _ in
                        HapticService.shared.selection()
                    }
                    
                    ScrollView {
                        if viewModel.selectedTab == .duplicates {
                            duplicatesContent
                        } else {
                            incompleteContent
                        }
                    }
                }
            }
        }
        .background(AmbientGlassBackdrop())
        .navigationTitle("Contacts Cleaner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.createDemoContacts()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Demo Data")
                    }
                    .font(.caption.weight(.semibold))
                }
            }
        }
        .sheet(item: $viewModel.selectedGroupForDetail) { group in
            ContactMergeDetailView(group: group, viewModel: viewModel)
        }
        .confirmationDialog(
            "Purge Incomplete Contacts",
            isPresented: $showingPurgeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Purge \(viewModel.incompleteContacts.count) Incomplete Contact(s)", role: .destructive) {
                Task {
                    await viewModel.purgeIncompleteContacts()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These contacts have no name or no phone/email. They will be permanently removed from your address book.")
        }
        .task {
            if permissionService.hasContactsAccess && viewModel.groups.isEmpty {
                await viewModel.load()
            }
        }
    }
    
    // MARK: - Duplicates Content
    @ViewBuilder
    private var duplicatesContent: some View {
        if viewModel.groups.isEmpty {
            emptyStateView(
                icon: "person.crop.circle.badge.checkmark",
                title: "No Duplicate Contacts",
                subtitle: "Your address book has no duplicate phone numbers, emails, or names."
            )
        } else {
            VStack(spacing: 16) {
                // Header with Merge All
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.groups.count) Duplicate Sets")
                            .font(.headline)
                        Text("\(viewModel.totalDuplicatesCount) duplicate cards to clean")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await viewModel.mergeAllGroups()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.merge")
                            Text("Merge All")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isMerging)
                }
                .liquidGlass(cornerRadius: 16, padding: 16)
                .padding(.horizontal)
                .padding(.top, 4)
                
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.groups) { group in
                        Button {
                            viewModel.selectedGroupForDetail = group
                        } label: {
                            HStack(spacing: 14) {
                                Text(group.primaryContact?.initials ?? "?")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue.gradient)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(group.primaryContact?.fullName ?? "Unnamed")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    HStack(spacing: 4) {
                                        Text(group.matchReason.rawValue)
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.green)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.12))
                                            .cornerRadius(6)
                                        
                                        Text("• \(group.contacts.count) cards")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            }
                            .liquidGlass(cornerRadius: 16, padding: 14)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 110)
        }
    }
    
    // MARK: - Incomplete Content
    @ViewBuilder
    private var incompleteContent: some View {
        if viewModel.incompleteContacts.isEmpty {
            emptyStateView(
                icon: "checkmark.seal.fill",
                title: "No Incomplete Contacts",
                subtitle: "Every contact in your address book has a valid name and reachable phone/email."
            )
        } else {
            VStack(spacing: 16) {
                // Header with Purge All
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.incompleteContacts.count) Incomplete Cards")
                            .font(.headline)
                        Text("Missing names, phone numbers, or emails")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(role: .destructive) {
                        showingPurgeConfirmation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                            Text("Purge All")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isMerging)
                }
                .liquidGlass(cornerRadius: 16, padding: 16)
                .padding(.horizontal)
                .padding(.top, 4)
                
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.incompleteContacts) { contact in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "questionmark")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(contact.fullName.isEmpty || contact.fullName == "No Name" ? "Unnamed Contact" : contact.fullName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                HStack(spacing: 6) {
                                    if contact.fullName.isEmpty || contact.fullName == "No Name" {
                                        Text("Missing Name")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.red)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.12))
                                            .cornerRadius(6)
                                    }
                                    if contact.phoneNumbers.isEmpty && contact.emailAddresses.isEmpty {
                                        Text("No Phone or Email")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.orange)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.12))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .liquidGlass(cornerRadius: 16, padding: 14)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 110)
        }
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text(title)
                .font(.title2.weight(.bold))
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 60)
    }
}
