// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftyMobileDevice",
    platforms: [
        .iOS("13.0"),
        .macOS("10.11")
    ],
    products: [
        .library(
            name: "SwiftyMobileDevice",
            type: .dynamic,
            targets: ["SwiftyMobileDevice"]
        ),
    ],
    dependencies: [
        .package(path: "../SuperchargeCore")
    ],
    targets: [
        .target(
            name: "SwiftyMobileDevice",
            dependencies: [
                .product(name: "plist", package: "SuperchargeCore"),
                .product(name: "usbmuxd", package: "SuperchargeCore"),
                .product(name: "libimobiledevice", package: "SuperchargeCore"),
                .product(name: "Superutils", package: "SuperchargeCore")
            ]
        ),
    ]
)
