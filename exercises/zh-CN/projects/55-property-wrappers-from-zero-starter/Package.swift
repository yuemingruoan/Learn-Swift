// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PropertyWrappersStarter",
    products: [
        .executable(
            name: "Wrappers",
            targets: ["Wrappers"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Wrappers"
        ),
        .testTarget(
            name: "WrappersTests",
            dependencies: ["Wrappers"]
        ),
    ]
)
