// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Seraph",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Seraph",
            targets: ["Seraph"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Seraph",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Files", package: "Files")
            ]
        )
    ]
)
