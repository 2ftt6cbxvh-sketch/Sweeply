import SwiftUI

@main
struct SweeplyApp: App {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init() {
        if ProcessInfo.processInfo.arguments.contains("-theme-light") {
            ThemeManager.shared.setTheme(.light)
        } else if ProcessInfo.processInfo.arguments.contains("-theme-dark") {
            ThemeManager.shared.setTheme(.dark)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
