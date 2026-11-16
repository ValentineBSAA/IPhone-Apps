// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DaySixIntegration",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "DaySixIntegration", targets: ["DaySixIntegration"])
    ],
    targets: [
        .target(name: "DaySixIntegration"),
        .testTarget(name: "DaySixIntegrationTests", dependencies: ["DaySixIntegration"])
    ]
)