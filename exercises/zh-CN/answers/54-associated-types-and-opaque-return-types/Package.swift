// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AssociatedTypesAndOpaqueAnswer",
    products: [
        .executable(
            name: "Storage",
            targets: ["Storage"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Storage"
        ),
        .testTarget(
            name: "StorageTests",
            dependencies: ["Storage"]
        ),
    ]
)
