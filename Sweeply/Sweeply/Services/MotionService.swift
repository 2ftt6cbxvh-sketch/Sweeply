import UIKit
import SwiftUI
import Combine
import CoreMotion

@MainActor
public final class MotionManager: ObservableObject {
    public static let shared = MotionManager()
    
    private let motionManager = CMMotionManager()
    @Published public var tiltX: CGFloat = 0.0
    @Published public var tiltY: CGFloat = 0.0
    
    private init() {
        startMotionUpdates()
    }
    
    public func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            let roll = CGFloat(motion.attitude.roll)
            let pitch = CGFloat(motion.attitude.pitch)
            
            let targetX = max(min(roll * 0.6, 1.0), -1.0)
            let targetY = max(min(pitch * 0.6, 1.0), -1.0)
            
            // Smooth damping
            let newX = self.tiltX * 0.82 + targetX * 0.18
            let newY = self.tiltY * 0.82 + targetY * 0.18
            
            // Deadband threshold: Only publish if visual difference is perceptible
            // Prevents 30-45 continuous frame invalidations per second when device is resting
            if abs(newX - self.tiltX) > 0.012 || abs(newY - self.tiltY) > 0.012 {
                self.tiltX = newX
                self.tiltY = newY
            }
        }
    }
    
    public func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

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
