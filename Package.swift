// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ZenTime",
    platforms: [.macOS(.v13)],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ZenTime",
            path: "ZenTime",
            resources: [
                .copy("Assets.xcassets")
            ]
        )
    ]
)
