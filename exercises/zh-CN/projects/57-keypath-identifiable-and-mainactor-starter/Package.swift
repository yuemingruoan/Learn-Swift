// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeyPathStarter",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .executable(
            name: "Toolkit",
            targets: ["Toolkit"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Toolkit"
        ),
        .testTarget(
            name: "ToolkitTests",
            dependencies: ["Toolkit"]
        ),
    ]
)
