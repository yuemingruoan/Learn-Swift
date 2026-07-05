// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftMacrosFromZero",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MacrosKit", targets: ["MacrosKit"]),
        .executable(name: "MacrosDemo", targets: ["MacrosDemo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .macro(
            name: "MacrosKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(name: "MacrosKit", dependencies: ["MacrosKitMacros"]),
        .executableTarget(name: "MacrosDemo", dependencies: ["MacrosKit"]),
        .testTarget(
            name: "MacrosKitTests",
            dependencies: [
                "MacrosKitMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
