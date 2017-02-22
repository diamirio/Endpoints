import PackageDescription

let package = Package(
    name: "EndpointsExample",
    dependencies: [
        .Package(url: "https://github.com/Hearst-DD/ObjectMapper.git", majorVersion: 2, minor: 2),
        .Package(url: "https://github.com/johnsundell/unbox.git", majorVersion: 2, minor: 3)
    ],
    exclude: [ "Tests" ]
)
