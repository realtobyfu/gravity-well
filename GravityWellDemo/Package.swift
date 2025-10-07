// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GravityWellDemo",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "GravityWellDemo",
            targets: ["GravityWellDemo"]
        )
    ],
    dependencies: [
        // Reference the local package
        .package(path: "../")
    ],
    targets: [
        .target(
            name: "GravityWellDemo",
            dependencies: [
                .product(name: "GravityWellKit", package: "GravityWell")
            ],
            path: "GravityWellDemo"
        )
    ]
)