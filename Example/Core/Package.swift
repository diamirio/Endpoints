import PackageDescription

let package = Package(
    name: "ExampleCore",
    dependencies: [
        .Package(url: "https://github.com/Hearst-DD/ObjectMapper.git", Version(2, 2, 3)),
        .Package(url: "https://github.com/johnsundell/unbox.git", Version(2, 3, 1)),
        .Package(url: "https://github.com/mxcl/PromiseKit", Version(4, 1, 7)),
    ],
    exclude: [ "Tests" ]
)
