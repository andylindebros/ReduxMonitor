// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReduxMonitor",
    platforms: [.iOS("13.0")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ReduxMonitor",
            targets: ["ReduxMonitor"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/ReSwift/ReSwift", from: "6.0.0"),
        .package(url: "https://github.com/lindebrothers/Logger", from: "0.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ReduxMonitor",
            dependencies: [
                .product(name: "ReSwift", package: "ReSwift"),
                .product(name: "Logger", package: "Logger"),
            ]),
        .testTarget(
            name: "ReduxMonitorTests",
            dependencies: ["ReduxMonitor"]),
    ]
)
