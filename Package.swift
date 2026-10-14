// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Revo",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Revo",
            path: "Sources/Revo"
        )
    ]
)
