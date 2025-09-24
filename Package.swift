// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GravityWell",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GravityWellKit",
            targets: ["GravityWellKit"]
        ),
        .executable(
            name: "GravityWellDemo",
            targets: ["GravityWellDemo"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "GravityWellKit",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/GravityWellKit"
        ),
        .executableTarget(
            name: "GravityWellDemo",
            dependencies: ["GravityWellKit"],
            path: "Sources/GravityWellDemo"
        ),
        .testTarget(
            name: "GravityWellKitTests",
            dependencies: ["GravityWellKit"],
            path: "Tests/GravityWellKitTests"
        )
    ]
)