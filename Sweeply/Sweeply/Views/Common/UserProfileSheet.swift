import SwiftUI

public struct UserProfileSheet: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAuthSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let user = authService.currentUser, authService.isAuthenticated && user.provider != .guest {
                    // Profile Avatar Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(user.provider == .apple ? Color.black : Color.red.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: user.provider == .apple ? "apple.logo" : "envelope.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(user.provider == .apple ? .white : .red)
                        }
                        .padding(.top, 16)
                        
                        Text(user.fullName)
                            .font(.title2.weight(.bold))
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("Signed in with \(user.provider.rawValue)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(8)
                    }
                    
                    // Features enabled
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ACCOUNT PERKS")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "icloud.fill")
                                .foregroundStyle(.blue)
                            Text("Unlimited Free Storage Scans")
                                .font(.subheadline)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundStyle(.green)
                            Text("On-Device Private & Safe Deletions")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    appearanceSection
                    
                    Spacer()
                    
                    // Sign Out Button
                    Button(role: .destructive) {
                        authService.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                } else {
                    // Not signed in / Guest state
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 24)
                        
                        Text("Sync & Profile")
                            .font(.title2.weight(.bold))
                        
                        Text("Connect your Apple ID or Google Account for a personalized cleaning experience.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button {
                            showingAuthSheet = true
                        } label: {
                            Text("Sign In / Create Account")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    
                    appearanceSection
                    
                    Spacer()
                }
            }
            .navigationTitle("Account & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAuthSheet) {
                AuthView()
            }
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPEARANCE")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            
            Picker("Theme", selection: Binding(
                get: { themeManager.currentTheme },
                set: { themeManager.setTheme($0) }
            )) {
                ForEach(ThemeMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
