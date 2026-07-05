// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeyPathIdentifiableAndMainActor",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "TaskKit",
            targets: ["TaskKit"]
        ),
        .executable(
            name: "TaskDemo",
            targets: ["TaskDemo"]
        ),
    ],
    targets: [
        .target(
            name: "TaskKit"
        ),
        .executableTarget(
            name: "TaskDemo",
            dependencies: ["TaskKit"]
        ),
        .testTarget(
            name: "TaskKitTests",
            dependencies: ["TaskKit"]
        ),
    ]
)
