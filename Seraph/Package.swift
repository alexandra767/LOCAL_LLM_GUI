// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Seraph",
    platforms: [
        .macOS(.v13),  // Require macOS 13 for NavigationStack
        .iOS(.v16)     // Require iOS 16 for NavigationStack
    ],
    products: [
        .library(
            name: "Seraph",
            targets: ["Seraph"]
        ),
        .library(
            name: "LLMService",
            targets: ["LLMService"]
        ),
        .executable(
            name: "SeraphApp",
            targets: ["SeraphApp"]
        )
    ],
    dependencies: [
        // Dependencies for the package
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.8.1")
    ],
    targets: [
        // Main library target
        .target(
            name: "Seraph",
            dependencies: [
                .product(name: "CombineExt", package: "CombineExt"),
                "LLMService"
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .unsafeFlags(["-enable-library-evolution"]),  // For better module stability
                .unsafeFlags(["-enable-testing"])
            ]
        ),
        
        // LLM Service target
        .target(
            name: "LLMService",
            dependencies: [],
            path: "Sources/LLMService",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .unsafeFlags(["-enable-library-evolution"]),  // For better module stability
                .unsafeFlags(["-enable-testing"])
            ]
        ),
        
        // App target
        .executableTarget(
            name: "SeraphApp",
            dependencies: ["Seraph"],
            path: "Sources/SeraphApp",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release))
            ]
        ),
        
        // Test target
        .testTarget(
            name: "SeraphTests",
            dependencies: ["Seraph"],
            path: "Tests/SeraphTests"
        )
    ]
)
