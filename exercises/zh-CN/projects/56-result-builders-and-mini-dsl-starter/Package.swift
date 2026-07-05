// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ResultBuildersStarter",
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
