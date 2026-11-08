// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "menu-bar-by-display",
    platforms: [.macOS(.v13)],
    targets: [
        // The decision lives in its own target so it can be tested without touching real displays or settings.
        .target(name: "MenuBarByDisplayCore"),
        .executableTarget(name: "menu-bar-by-display", dependencies: ["MenuBarByDisplayCore"]),
        .testTarget(name: "MenuBarByDisplayCoreTests", dependencies: ["MenuBarByDisplayCore"]),
    ]
)
