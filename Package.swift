// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "Endpoints",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v12),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Endpoints",
            targets: ["Endpoints"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Endpoints",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "EndpointsTests",
            dependencies: [
                "Endpoints"
            ],
            path: "Tests",
            resources: [
                .process("TestResources")
            ]
        )
    ]
)
