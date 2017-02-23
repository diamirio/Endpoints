import PackageDescription

let package = Package(
    name: "ExampleCore",
    dependencies: [
        .Package(url: "https://github.com/Hearst-DD/ObjectMapper.git", Version(2, 2, 3)),
        .Package(url: "https://github.com/johnsundell/unbox.git", Version(2, 3, 1))
    ],
    exclude: [ "Tests" ]
)
