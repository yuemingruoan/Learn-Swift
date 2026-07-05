// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ResultBuildersAndMiniDSL",
    products: [
        .library(
            name: "HTMLDSL",
            targets: ["HTMLDSL"]
        ),
        .executable(
            name: "HTMLDemo",
            targets: ["HTMLDemo"]
        ),
    ],
    targets: [
        .target(
            name: "HTMLDSL"
        ),
        .executableTarget(
            name: "HTMLDemo",
            dependencies: ["HTMLDSL"]
        ),
        .testTarget(
            name: "HTMLDSLTests",
            dependencies: ["HTMLDSL"]
        ),
    ]
)
