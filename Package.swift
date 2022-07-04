// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Endpoints",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Endpoints",
            targets: ["Endpoints"]
        )
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
                .process("TestResources"),
            ]
        )
    ]
)
