// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Learper",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Learper", targets: ["Learper"])],
    targets: [
        .executableTarget(
            name: "Learper",
            resources: [.process("Resources")]
        ),
        .testTarget(name: "LearperTests", dependencies: ["Learper"])
    ]
)
