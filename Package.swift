// swift-tools-version:5.9
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
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.4")
    ],
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
