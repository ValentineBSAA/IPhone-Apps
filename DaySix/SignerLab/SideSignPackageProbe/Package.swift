// swift-tools-version: 5.9
import PackageDescription

/// Experimental library-linkage probe. Does NOT perform authentication,
/// certificate provisioning, signing, installation, or self-renewal.
let package = Package(
    name: "DaySixSideSignProbe",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/SideStore/SideSign.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "DaySixSideSignProbe",
            dependencies: [
                .product(name: "SideSign", package: "SideSign")
            ],
            path: "Sources"
        )
    ]
)
