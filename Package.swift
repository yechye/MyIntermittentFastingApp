// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FastingApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FastingApp", targets: ["FastingApp"])
    ],
    targets: [
        .executableTarget(
            name: "FastingApp",
            path: "FastingApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FastingAppTests",
            dependencies: ["FastingApp"],
            path: "FastingAppTests"
        )
    ]
)
