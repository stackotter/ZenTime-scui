// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ZenTime",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/moreSwift/swift-cross-ui", .upToNextMinor(from: "0.8.0")),
    ],
    targets: [
        .executableTarget(
            name: "ZenTime",
            dependencies: [
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui")
            ],
            path: "ZenTime",
            resources: [
                .copy("Assets.xcassets")
            ]
        )
    ]
)
