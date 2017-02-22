import PackageDescription

let package = Package(
    name: "ExampleCore",
    dependencies: [
        .Package(url: "https://github.com/Hearst-DD/ObjectMapper.git", majorVersion: 2, minor: 2, patch: 3),
        .Package(url: "https://github.com/johnsundell/unbox.git", majorVersion: 2, minor: 3, patch: 1)
    ],
    exclude: [ "Tests" ]
)
