import SwiftUI

@main
struct SweeplyApp: App {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
