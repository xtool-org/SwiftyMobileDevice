// swift-tools-version:6.0

import PackageDescription

extension Product.Library.LibraryType {
    static var smart: Self {
        #if os(Linux)
        return .static
        #else
        return .dynamic
        #endif
    }
}

let package = Package(
    name: "SwiftyMobileDevice",
    platforms: [
        .iOS("14.0"),
        .macOS("11.0"),
    ],
    products: [
        .library(
            name: "SwiftyMobileDevice",
            type: .smart,
            targets: ["SwiftyMobileDevice"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/xtool-org/xtool-core", .upToNextMinor(from: "1.4.0")),
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
