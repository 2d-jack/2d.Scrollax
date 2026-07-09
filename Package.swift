// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Scrollax",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Scrollax",
            path: "Sources/Scrollax"
        )
    ]
)
