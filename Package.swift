// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pane",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Pane",
            path: "Pane"
        ),
        .testTarget(
            name: "PaneTests",
            dependencies: ["Pane"],
            path: "PaneTests"
        ),
    ]
)
