import SwiftUI
import Combine

public enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    public var id: String { rawValue }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    public var iconName: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    private let storageKey = "sweeply_user_theme_preference"
    
    @Published public var currentTheme: ThemeMode = .light {
        didSet {
            if !ProcessInfo.processInfo.arguments.contains("-theme-dark") &&
               !ProcessInfo.processInfo.arguments.contains("-theme-light") {
                UserDefaults.standard.set(currentTheme.rawValue, forKey: storageKey)
            }
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: storageKey) ?? ThemeMode.light.rawValue
        self.currentTheme = ThemeMode(rawValue: saved) ?? .light
    }
    
    public var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
    
    public func setTheme(_ theme: ThemeMode) {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentTheme = theme
        }
    }
    
    public func toggleTheme() {
        switch currentTheme {
        case .light:
            setTheme(.dark)
        case .dark:
            setTheme(.light)
        case .system:
            setTheme(.dark)
        }
    }
}
