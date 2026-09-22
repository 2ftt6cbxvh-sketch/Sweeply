import UIKit
import SwiftUI
import Combine

public extension NSNotification.Name {
    static let deviceDidShake = NSNotification.Name("com.sweeply.deviceDidShake")
}

// Intercept shake gesture on UIWindow
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}

public struct UndoItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let itemCount: Int
    public let bytesFreed: Int64
    public let timestamp: Date
    
    public init(title: String, itemCount: Int, bytesFreed: Int64) {
        self.title = title
        self.itemCount = itemCount
        self.bytesFreed = bytesFreed
        self.timestamp = Date()
    }
}

@MainActor
public final class UndoService: ObservableObject {
    public static let shared = UndoService()
    
    @Published public var lastCleanAction: UndoItem? = nil
    @Published public var showingShakeAlert: Bool = false
    
    private init() {}
    
    public func recordClean(title: String, count: Int, bytes: Int64) {
        self.lastCleanAction = UndoItem(title: title, itemCount: count, bytesFreed: bytes)
    }
    
    public func clearLastAction() {
        self.lastCleanAction = nil
    }
}
