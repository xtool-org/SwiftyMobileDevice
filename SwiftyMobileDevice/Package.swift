// swift-tools-version:5.3

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
        .iOS("13.0"),
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "SwiftyMobileDevice",
            type: .smart,
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
