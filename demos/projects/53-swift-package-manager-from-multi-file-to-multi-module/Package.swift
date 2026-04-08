// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StudyPlanPackage",
    products: [
        .library(
            name: "StudyPlanCore",
            targets: ["StudyPlanCore"]
        ),
        .executable(
            name: "study-plan",
            targets: ["StudyPlanCLI"]
        ),
    ],
    targets: [
        .target(
            name: "StudyPlanCore"
        ),
        .executableTarget(
            name: "StudyPlanCLI",
            dependencies: ["StudyPlanCore"]
        ),
        .testTarget(
            name: "StudyPlanCoreTests",
            dependencies: ["StudyPlanCore"]
        ),
    ]
)
