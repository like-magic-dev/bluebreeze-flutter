// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bluebreeze",
    platforms: [
        .iOS("13.0"),
        .macOS("11.5")
    ],
    products: [
        .library(name: "bluebreeze", targets: ["BluebreezeFlutter", "bluebreezeShim"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/like-magic-dev/bluebreeze-ios", from: "1.0.1"),
    ],
    targets: [
        .target(
            // Named differently than the "bluebreeze" product: on case-insensitive filesystems
            // (default macOS APFS), a target named "bluebreeze" collides with the "BlueBreeze"
            // target from the bluebreeze-ios dependency, since Xcode derives each target's
            // intermediate build directory from its name. `bluebreezeShim` below re-exposes this
            // target under the "bluebreeze" header name that Flutter's generated plugin
            // registrant expects.
            name: "BluebreezeFlutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "BlueBreeze", package: "bluebreeze-ios"),
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .target(
            // Header-only shim so `#import <bluebreeze/BluebreezePlugin.h>` (used by Flutter's
            // generated GeneratedPluginRegistrant.m) resolves without needing a target literally
            // named "bluebreeze".
            name: "bluebreezeShim",
            dependencies: ["BluebreezeFlutter"],
            publicHeadersPath: "include"
        ),
    ]
)
