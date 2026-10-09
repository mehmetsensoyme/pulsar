// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pulsar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Pulsar", targets: ["Pulsar"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Pulsar",
            path: "Sources/Pulsar",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
