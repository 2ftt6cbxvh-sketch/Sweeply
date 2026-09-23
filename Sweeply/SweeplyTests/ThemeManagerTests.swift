import XCTest
import SwiftUI
@testable import Sweeply

@MainActor
final class ThemeManagerTests: XCTestCase {
    
    func testThemeModeColorSchemes() {
        XCTAssertNil(ThemeMode.system.colorScheme)
        XCTAssertEqual(ThemeMode.light.colorScheme, .light)
        XCTAssertEqual(ThemeMode.dark.colorScheme, .dark)
    }
    
    func testDefaultThemeIsLight() {
        // Ensure default rawValue is "Light"
        XCTAssertEqual(ThemeMode.light.rawValue, "Light")
        XCTAssertEqual(ThemeMode.light.colorScheme, .light)
    }
    
    func testThemeToggleCycle() {
        let manager = ThemeManager.shared
        
        // Set to light
        manager.setTheme(.light)
        XCTAssertEqual(manager.currentTheme, .light)
        XCTAssertEqual(manager.colorScheme, .light)
        
        // Toggle should switch to dark
        manager.toggleTheme()
        XCTAssertEqual(manager.currentTheme, .dark)
        XCTAssertEqual(manager.colorScheme, .dark)
        
        // Toggle again should switch back to light
        manager.toggleTheme()
        XCTAssertEqual(manager.currentTheme, .light)
        XCTAssertEqual(manager.colorScheme, .light)
        
        // Toggle from system switches to dark
        manager.setTheme(.system)
        XCTAssertEqual(manager.currentTheme, .system)
        XCTAssertNil(manager.colorScheme)
        manager.toggleTheme()
        XCTAssertEqual(manager.currentTheme, .dark)
    }
}
