// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bluebreeze_flutter",
    platforms: [
        .iOS("13.0"),
        .macOS("11.5")
    ],
    products: [
        // If the plugin name contains "_", replace with "-" for the library name.
        .library(name: "bluebreeze-flutter", targets: ["bluebreeze_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/like-magic-dev/bluebreeze-ios", from: "0.0.24"),
    ],
    targets: [
        .target(
            name: "bluebreeze_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "BlueBreeze", package: "bluebreeze-ios"),
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
