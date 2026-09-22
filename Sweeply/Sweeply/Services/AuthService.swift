import Foundation
import AuthenticationServices
import SwiftUI
import Combine

public enum AuthProvider: String, Codable {
    case apple = "Apple"
    case google = "Google"
    case guest = "Guest"
}

public struct AuthUser: Codable, Identifiable {
    public let id: String
    public var email: String
    public var fullName: String
    public var provider: AuthProvider
    
    public init(id: String, email: String, fullName: String, provider: AuthProvider) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.provider = provider
    }
}

@MainActor
public final class AuthService: ObservableObject {
    public static let shared = AuthService()
    
    @Published public var currentUser: AuthUser? = nil
    @Published public var isAuthenticated: Bool = false
    @Published public var errorMessage: String? = nil
    
    private let userDefaultsKey = "com.sweeply.currentUser"
    
    private init() {
        loadPersistedUser()
    }
    
    private func loadPersistedUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(AuthUser.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    private func persistUser(_ user: AuthUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    public func handleAppleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                
                var name = ""
                if let givenName = appleIDCredential.fullName?.givenName {
                    name = givenName
                    if let familyName = appleIDCredential.fullName?.familyName {
                        name += " \(familyName)"
                    }
                }
                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    name = "Apple User"
                }
                
                let email = appleIDCredential.email ?? "apple.id@privaterelay.appleid.com"
                
                let user = AuthUser(
                    id: userId,
                    email: email,
                    fullName: name,
                    provider: .apple
                )
                
                persistUser(user)
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func signInWithGoogle(email: String = "user@gmail.com", name: String = "Google User") {
        let user = AuthUser(
            id: UUID().uuidString,
            email: email,
            fullName: name,
            provider: .google
        )
        persistUser(user)
    }
    
    public func continueAsGuest() {
        let guest = AuthUser(
            id: UUID().uuidString,
            email: "guest@sweeply.local",
            fullName: "Guest User",
            provider: .guest
        )
        persistUser(guest)
    }
    
    public func signOut() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
