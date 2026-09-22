import SwiftUI

@main
struct SweeplyApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(.light)
        }
    }
}
