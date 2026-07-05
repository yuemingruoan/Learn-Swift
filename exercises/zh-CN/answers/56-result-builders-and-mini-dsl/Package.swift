// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ResultBuildersAnswer",
    products: [
        .executable(
            name: "MenuApp",
            targets: ["MenuApp"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "MenuApp"
        ),
        .testTarget(
            name: "MenuAppTests",
            dependencies: ["MenuApp"]
        ),
    ]
)
