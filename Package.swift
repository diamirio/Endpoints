// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "Endpoints",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v12),
    ],
    products: [
        .library(
            name: "Endpoints",
            targets: ["Endpoints"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", .upToNextMajor(from: "0.54.0")),
    ],
    targets: [
        .target(
            name: "Endpoints",
            dependencies: [],
            path: "Sources",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
        .testTarget(
            name: "EndpointsTests",
            dependencies: [
                "Endpoints",
            ],
            path: "Tests",

            resources: [
                .process("TestResources"),
            ]
        ),
    ]
)
