// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "URLMacroStarter",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "URLKit", targets: ["URLKit"]),
        .executable(name: "URLDemo", targets: ["URLDemo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .macro(
            name: "URLKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(name: "URLKit", dependencies: ["URLKitMacros"]),
        .executableTarget(name: "URLDemo", dependencies: ["URLKit"]),
        .testTarget(
            name: "URLKitTests",
            dependencies: [
                "URLKitMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
