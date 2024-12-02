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
        .package(url: "https://github.com/SuperchargeApp/SuperchargeCore", .upToNextMinor(from: "1.2.0")),
    ],
    targets: [
        .target(
            name: "SwiftyMobileDevice",
            dependencies: [
                .product(name: "plist", package: "SuperchargeCore"),
                .product(name: "libimobiledeviceGlue", package: "SuperchargeCore"),
                .product(name: "usbmuxd", package: "SuperchargeCore"),
                .product(name: "libimobiledevice", package: "SuperchargeCore"),
                .product(name: "Superutils", package: "SuperchargeCore")
            ]
        ),
    ]
)
