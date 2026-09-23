import Foundation
import Photos
import Contacts
import UIKit
import Combine

@MainActor
public final class PermissionService: ObservableObject {
    public static let shared = PermissionService()
    
    @Published public var photoStatus: PHAuthorizationStatus = .notDetermined
    @Published public var contactStatus: CNAuthorizationStatus = .notDetermined
    
    public init() {
        checkCurrentStatuses()
    }
    
    public func checkCurrentStatuses() {
        if ProcessInfo.processInfo.arguments.contains("-grant-all-permissions") {
            photoStatus = .authorized
            contactStatus = .authorized
            return
        }
        photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        contactStatus = CNContactStore.authorizationStatus(for: .contacts)
    }
    
    public var hasPhotosAccess: Bool {
        photoStatus == .authorized || photoStatus == .limited
    }
    
    public var isPhotosLimited: Bool {
        photoStatus == .limited
    }
    
    public var isPhotosDenied: Bool {
        photoStatus == .denied || photoStatus == .restricted
    }
    
    public var hasContactsAccess: Bool {
        contactStatus == .authorized
    }
    
    public func requestPhotosPermission() async -> PHAuthorizationStatus {
        if ProcessInfo.processInfo.arguments.contains("-grant-all-permissions") {
            self.photoStatus = .authorized
            return .authorized
        }
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.photoStatus = status
        return status
    }
    
    public func requestContactsPermission() async -> Bool {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            self.contactStatus = granted ? .authorized : .denied
            return granted
        } catch {
            self.contactStatus = .denied
            return false
        }
    }
    
    public func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
