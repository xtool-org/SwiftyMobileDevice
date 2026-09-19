// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "SwiftyMobileDevice",
    platforms: [
        .iOS("14.0"),
        .macOS("11.0"),
    ],
    products: [
        .library(
            name: "SwiftyMobileDevice",
            targets: ["SwiftyMobileDevice"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/xtool-org/xtool-core", branch: "not-smart"),
    ],
    targets: [
        .target(
            name: "SwiftyMobileDevice",
            dependencies: [
                .product(name: "plist", package: "xtool-core"),
                .product(name: "libimobiledeviceGlue", package: "xtool-core"),
                .product(name: "usbmuxd", package: "xtool-core"),
                .product(name: "libimobiledevice", package: "xtool-core"),
                .product(name: "Superutils", package: "xtool-core")
            ]
        ),
    ]
)
