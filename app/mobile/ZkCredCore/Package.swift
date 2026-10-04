// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ZkCredCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "ZkCredCore", targets: ["ZkCredCore"])],
    dependencies: [.package(url: "https://github.com/apple/swift-crypto.git", "3.0.0"..<"5.0.0")],
    targets: [
        .target(
            name: "ZkCredCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "CryptoExtras", package: "swift-crypto"),
            ]
        ),
        .testTarget(
            name: "ZkCredCoreTests",
            dependencies: ["ZkCredCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
