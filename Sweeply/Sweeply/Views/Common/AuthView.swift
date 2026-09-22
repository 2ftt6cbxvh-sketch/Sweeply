import SwiftUI
import AuthenticationServices

public struct AuthView: View {
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingGooglePrompt = false
    @State private var inputGoogleEmail = ""
    @State private var inputGoogleName = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // App Logo & Title
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .shadow(color: Color.blue.opacity(0.35), radius: 14, x: 0, y: 6)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 42))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Welcome to Sweeply")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text("Free up storage, find duplicates, and keep your iPhone fast & tidy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Feature Highlights
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                            .frame(width: 28)
                        Text("Detect similar & duplicate photos in seconds")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.orange)
                            .frame(width: 28)
                        Text("Sort large videos and compress to save gigabytes")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.green)
                            .frame(width: 28)
                        Text("Merge duplicate contacts with 1 tap")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.purple)
                            .frame(width: 28)
                        Text("100% On-Device & Safe Deletion")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .padding(20)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(18)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Auth Buttons
                VStack(spacing: 12) {
                    // Sign in with Apple Button (Native)
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            authService.handleAppleAuthorization(result: result)
                            if authService.isAuthenticated {
                                dismiss()
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(14)
                    
                    // Sign in with Google / Gmail Button
                    Button {
                        showingGooglePrompt = true
                    } label: {
                        HStack(spacing: 10) {
                            // Google "G" icon design
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 22, height: 22)
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.red)
                            }
                            Text("Continue with Gmail / Google")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(uiColor: .systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(uiColor: .systemGray4), lineWidth: 1.2)
                        )
                        .cornerRadius(14)
                    }
                    
                    // Guest / Skip Button
                    Button {
                        authService.continueAsGuest()
                        dismiss()
                    } label: {
                        Text("Continue as Guest")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGooglePrompt) {
                GoogleSignInSheet { email, name in
                    authService.signInWithGoogle(email: email, name: name)
                    showingGooglePrompt = false
                    dismiss()
                }
            }
        }
    }
}

public struct GoogleSignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let onSignIn: (String, String) -> Void
    
    @State private var email: String = "ganeshvarma@gmail.com"
    @State private var name: String = "Ganesh Varma"
    
    public init(onSignIn: @escaping (String, String) -> Void) {
        self.onSignIn = onSignIn
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.red)
                    }
                    .padding(.top, 16)
                    
                    Text("Sign in with Google")
                        .font(.title2.weight(.bold))
                    
                    Text("Connect your Gmail account to sync your cleaning reports across devices.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Form Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("GMAIL / GOOGLE EMAIL")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        
                        TextField("name@gmail.com", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding(14)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FULL NAME")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        
                        TextField("Your Name", text: $name)
                            .padding(14)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                // Quick 1-tap Account preset
                Button {
                    onSignIn("ganeshvarma@gmail.com", "Ganesh Varma")
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick 1-Tap Sign In")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("ganeshvarma@gmail.com")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Submit Button
                Button {
                    let finalEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "user@gmail.com" : email.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Google User" : name.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSignIn(finalEmail, finalName)
                } label: {
                    Text("Sign In with Google")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.red)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
