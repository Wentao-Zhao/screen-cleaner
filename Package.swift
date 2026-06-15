// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScreenCleaner",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ScreenCleaner", targets: ["ScreenCleaner"]),
        .executable(name: "ScreenCleanerLogicTests", targets: ["ScreenCleanerLogicTests"])
    ],
    targets: [
        .target(
            name: "ScreenCleanerCore",
            path: "Sources/ScreenCleanerCore"
        ),
        .executableTarget(
            name: "ScreenCleaner",
            dependencies: ["ScreenCleanerCore"],
            path: "Sources/ScreenCleaner"
        ),
        .executableTarget(
            name: "ScreenCleanerLogicTests",
            dependencies: ["ScreenCleanerCore"],
            path: "Tests/ScreenCleanerTests"
        )
    ]
)
