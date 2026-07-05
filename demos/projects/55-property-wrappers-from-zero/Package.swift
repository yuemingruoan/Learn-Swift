// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PropertyWrappersFromZero",
    products: [
        .library(
            name: "WrapperKit",
            targets: ["WrapperKit"]
        ),
        .executable(
            name: "WrapperDemo",
            targets: ["WrapperDemo"]
        ),
    ],
    targets: [
        .target(
            name: "WrapperKit"
        ),
        .executableTarget(
            name: "WrapperDemo",
            dependencies: ["WrapperKit"]
        ),
        .testTarget(
            name: "WrapperKitTests",
            dependencies: ["WrapperKit"]
        ),
    ]
)
