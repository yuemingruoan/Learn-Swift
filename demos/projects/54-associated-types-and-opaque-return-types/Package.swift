// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AssociatedTypesAndOpaque",
    products: [
        .library(
            name: "ContainerKit",
            targets: ["ContainerKit"]
        ),
        .executable(
            name: "ContainerDemo",
            targets: ["ContainerDemo"]
        ),
    ],
    targets: [
        .target(
            name: "ContainerKit"
        ),
        .executableTarget(
            name: "ContainerDemo",
            dependencies: ["ContainerKit"]
        ),
        .testTarget(
            name: "ContainerKitTests",
            dependencies: ["ContainerKit"]
        ),
    ]
)
