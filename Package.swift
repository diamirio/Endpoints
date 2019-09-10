// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Endpoints",
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
            path: "Tests"
        )
    ]
)
