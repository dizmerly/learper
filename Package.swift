// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Learper",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Learper", targets: ["Learper"])],
    targets: [
        .executableTarget(
            name: "Learper",
            resources: [
                .copy("Resources/Web"),
                .process("Resources/sample-quiz.json"),
                .process("Resources/graph-theory-quiz.json")
            ]
        ),
        .testTarget(name: "LearperTests", dependencies: ["Learper"])
    ]
)
