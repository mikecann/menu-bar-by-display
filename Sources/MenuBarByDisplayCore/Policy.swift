/// The two values behind System Settings > Control Center > "Automatically hide and show the menu bar".
/// macOS stores them as `_HIHideMenuBar` and `AppleMenuBarVisibleInFullscreen` in the global domain.
public struct MenuBarSetting: Equatable, CustomStringConvertible {
    public var hideOnDesktop: Bool
    public var showInFullScreen: Bool

    public init(hideOnDesktop: Bool, showInFullScreen: Bool) {
        self.hideOnDesktop = hideOnDesktop
        self.showInFullScreen = showInFullScreen
    }

    /// "Never" in System Settings: the menu bar is always on screen, full screen included.
    public static let alwaysShown = MenuBarSetting(hideOnDesktop: false, showInFullScreen: true)
    /// "Always" in System Settings: the menu bar hides until you move the pointer to the top.
    public static let autoHides = MenuBarSetting(hideOnDesktop: true, showInFullScreen: false)

    public var description: String {
        switch self {
        case .alwaysShown: return "always shown"
        case .autoHides: return "auto-hides"
        default: return "hide on desktop \(hideOnDesktop), show in full screen \(showInFullScreen)"
        }
    }
}

/// What the menu bar should do for the displays that are on right now.
/// `builtinFlags` has one entry per active display, true for the laptop's own screen.
/// Returns nil when there are no active displays (asleep, or mid-switch), so nothing changes.
public func menuBarSetting(forActiveDisplays builtinFlags: [Bool]) -> MenuBarSetting? {
    guard !builtinFlags.isEmpty else { return nil }
    // The notch already takes that strip on the laptop screen, so hiding the menu bar there buys nothing.
    // Any external display (including lid shut with a monitor plugged in) gets the space back by hiding it.
    return builtinFlags.allSatisfy { $0 } ? .alwaysShown : .autoHides
}
