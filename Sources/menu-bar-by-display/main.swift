// menu-bar-by-display: keeps the macOS menu bar on screen when the laptop's own display is the only
// one, and auto-hides it when an external monitor is plugged in. macOS has a single global setting
// for this, so the tool watches for display changes and flips it.
//
//   menu-bar-by-display          watch displays and keep the setting right (what the LaunchAgent runs)
//   menu-bar-by-display status   print the displays and what the menu bar is set to
//   menu-bar-by-display apply    set it once for the current displays and exit
import AppKit
import MenuBarByDisplayCore

let hideKey = "_HIHideMenuBar" as CFString
let fullScreenKey = "AppleMenuBarVisibleInFullscreen" as CFString

func log(_ message: String) {
    FileHandle.standardError.write("\(Date()) \(message)\n".data(using: .utf8)!)
}

func activeDisplays() -> [CGDirectDisplayID] {
    var count: UInt32 = 0
    guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
    var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
    guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }
    return Array(ids.prefix(Int(count)))
}

func readBool(_ key: CFString) -> Bool? {
    CFPreferencesCopyAppValue(key, kCFPreferencesAnyApplication) as? Bool
}

func currentSetting() -> MenuBarSetting {
    // A long-running process caches preferences, so pull fresh values first. Otherwise a change made
    // elsewhere (System Settings, a macOS update) looks like the old value and never gets put back.
    CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
    // Missing keys mean the macOS default: shown on the desktop, hidden in full screen.
    return MenuBarSetting(hideOnDesktop: readBool(hideKey) ?? false, showInFullScreen: readBool(fullScreenKey) ?? false)
}

func wantedSetting() -> MenuBarSetting? {
    menuBarSetting(forActiveDisplays: activeDisplays().map { CGDisplayIsBuiltin($0) != 0 })
}

func apply() {
    guard let wanted = wantedSetting(), currentSetting() != wanted else { return }
    CFPreferencesSetAppValue(hideKey, wanted.hideOnDesktop as CFBoolean, kCFPreferencesAnyApplication)
    CFPreferencesSetAppValue(fullScreenKey, wanted.showInFullScreen as CFBoolean, kCFPreferencesAnyApplication)
    CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
    // System Settings posts this after changing the option. It's what makes the menu bar and
    // windows move straight away instead of after a logout.
    DistributedNotificationCenter.default().postNotificationName(
        NSNotification.Name("AppleInterfaceMenuBarHidingChangedNotification"),
        object: nil, userInfo: nil, deliverImmediately: true)
    log("menu bar \(wanted)")
}

func printStatus() {
    print("Displays:")
    for id in activeDisplays() {
        let size = CGDisplayBounds(id).size
        print("  \(CGDisplayIsBuiltin(id) != 0 ? "built-in" : "external") \(Int(size.width))x\(Int(size.height))")
    }
    print("Menu bar now: \(currentSetting())")
    print("Menu bar wanted: \(wantedSetting().map(\.description) ?? "leave as is")")
}

switch CommandLine.arguments.dropFirst().first {
case "status":
    printStatus()
    exit(0)
case "apply":
    apply()
    exit(0)
case nil:
    break
default:
    FileHandle.standardError.write("usage: menu-bar-by-display [status|apply]\n".data(using: .utf8)!)
    exit(64)
}

var pending: DispatchWorkItem?
CGDisplayRegisterReconfigurationCallback({ _, flags, _ in
    if flags.contains(.beginConfigurationFlag) { return }
    // Plugging in a monitor fires a burst of callbacks, so wait for the layout to settle.
    pending?.cancel()
    let work = DispatchWorkItem { apply() }
    pending = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
}, nil)

// Check again after sleep too, in case a monitor was plugged in or pulled out while the lid was shut.
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in apply() }

// Safety net. On 8-9 Nov the callbacks above never fired under launchd (the log stayed empty through a
// monitor unplug, a wake and a replug) and the menu bar stayed shown on the monitors. Checking every few
// seconds is a display list and two preference reads, so it costs next to nothing and can't be missed.
let poll = Timer(timeInterval: 5, repeats: true) { _ in apply() }
poll.tolerance = 2
RunLoop.main.add(poll, forMode: .common)

log("started, displays \(activeDisplays().map { CGDisplayIsBuiltin($0) != 0 ? "built-in" : "external" }), menu bar \(currentSetting())")
apply()
RunLoop.main.run()
