// swift-tools-version:6.0
import PackageDescription

// Backup path: My Number Card in a USB PC/SC reader on a Mac instead of the iPhone's NFC.
let package = Package(
    name: "ZkCredMac",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "../ZkCredCore")],
    targets: [
        .executableTarget(
            name: "zkcred-mac",
            dependencies: [.product(name: "ZkCredCore", package: "ZkCredCore")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
