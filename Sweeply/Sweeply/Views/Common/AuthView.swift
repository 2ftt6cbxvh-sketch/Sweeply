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
            .alert("Sign in with Google", isPresented: $showingGooglePrompt) {
                TextField("Enter Gmail Address", text: $inputGoogleEmail)
                    .textInputAutocapitalization(.never)
                Button("Sign In") {
                    let email = inputGoogleEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalEmail = email.isEmpty ? "user@gmail.com" : email
                    let name = finalEmail.components(separatedBy: "@").first?.capitalized ?? "Google User"
                    authService.signInWithGoogle(email: finalEmail, name: name)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your Gmail address to connect your account for free.")
            }
        }
    }
}
