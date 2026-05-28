// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LLMFlex",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LLMFlex", targets: ["LLMFlex"]),
        .library(name: "LLMFlexCore", targets: ["LLMFlexCore"]),
    ],
    targets: [
        .executableTarget(
            name: "LLMFlex",
            dependencies: ["LLMFlexCore"],
            path: "Sources/LLMFlex",
            resources: [.process("Resources")]
        ),
        .target(
            name: "LLMFlexCore",
            path: "Sources/LLMFlexCore"
        ),
        .testTarget(
            name: "LLMFlexCoreTests",
            dependencies: ["LLMFlexCore"],
            path: "Tests/LLMFlexCoreTests"
        ),
    ]
)
