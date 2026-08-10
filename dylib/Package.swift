// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "LicenseManager",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "LicenseManager",
            targets: ["LicenseManager"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LicenseManager",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "LicenseManagerTests",
            dependencies: ["LicenseManager"],
            path: "Tests"
        ),
    ]
)
