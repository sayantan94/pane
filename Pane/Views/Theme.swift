import SwiftUI

let warmAccent = Color(red: 0.82, green: 0.52, blue: 0.38)

func displayName(for index: Int) -> String {
    let screens = NSScreen.screens
    guard index < screens.count else { return "Display \(index + 1)" }
    if screens[index] == NSScreen.main { return "Built-in Display" }
    return screens[index].localizedName
}
