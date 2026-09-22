import SwiftUI

public struct DuplicateContactsView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @StateObject private var permissionService = PermissionService.shared
    
    public init() {}
    
    public var body: some View {
        Group {
            if !permissionService.hasContactsAccess {
                PermissionNoticeView(
                    title: "Contacts Access Required",
                    message: "Sweeply scans contacts locally to find and clean duplicates.",
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
                ProgressView("Analyzing contacts...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.groups.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("No Duplicate Contacts")
                        .font(.title2.weight(.bold))
                    
                    Text("Your address book is clean and deduplicated.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button {
                        Task {
                            await viewModel.createDemoContacts()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Demo Duplicate Contacts")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(14)
                    }
                    .padding(.top, 8)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header banner with "Merge All"
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
                                .cornerRadius(10)
                            }
                            .disabled(viewModel.isMerging)
                        }
                        .padding(16)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        // Groups list
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.groups) { group in
                                Button {
                                    viewModel.selectedGroupForDetail = group
                                } label: {
                                    HStack(spacing: 14) {
                                        // Initials Circle
                                        Text(group.primaryContact?.initials ?? "?")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.blue.gradient)
                                            .clipShape(Circle())
                                        
                                        // Name and Match info
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
                                                    .cornerRadius(4)
                                                
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
                                    .padding(14)
                                    .background(Color(uiColor: .systemBackground))
                                    .cornerRadius(14)
                                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Duplicate Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.selectedGroupForDetail) { group in
            ContactMergeDetailView(group: group, viewModel: viewModel)
        }
        .task {
            if permissionService.hasContactsAccess && viewModel.groups.isEmpty {
                await viewModel.load()
            }
        }
    }
}
