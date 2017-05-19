import PackageDescription

let package = Package(
    name: "ExampleCore",
    dependencies: [
        .Package(url: "https://github.com/mxcl/PromiseKit", Version(4, 1, 7)),
    ],
    exclude: [ "Tests" ]
)
