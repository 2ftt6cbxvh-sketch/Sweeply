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
    
    private let storageKey = "sweeply_theme_mode"
    
    @Published public var currentTheme: ThemeMode = .system {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: storageKey)
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: storageKey) ?? ThemeMode.system.rawValue
        self.currentTheme = ThemeMode(rawValue: saved) ?? .system
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
