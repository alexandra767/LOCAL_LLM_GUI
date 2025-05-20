// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Seraph",
    platforms: [
        .macOS(.v13) // Set minimum version to macOS 13.0
    ],
    products: [
        .executable(
            name: "Seraph",
            targets: ["Seraph"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", from: "2.2.0"),
        .package(url: "https://github.com/kean/Nuke.git", from: "12.1.0"),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "Seraph",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "NukeUI", package: "Nuke"),
                .product(name: "Introspect", package: "SwiftUI-Introspect")
            ],
            path: "Sources/Seraph"
        )
    ]
)
