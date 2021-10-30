// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Sparkly",
  platforms: [.macOS(.v11)],
  products: [
    .library(
      name: "Sparkly",
      targets: ["Sparkly"]
    ),
    .library(
      name: "SparklyCommands",
      targets: ["SparklyCommands"]
    ),
    .library(
      name: "SparklyClient",
      targets: ["SparklyClient"]
    ),
    .library(
      name: "SparklyClientLive",
      targets: ["SparklyClientLive"]
    ),
  ],
  dependencies: [
    .package(
      name: "Sparkle",
      url: "https://github.com/sparkle-project/Sparkle",
      .exact(
        Version(2, 0, 0, prereleaseIdentifiers: ["beta", "4"], buildMetadataIdentifiers: [])
      )
    ),
    .package(
      name: "combine-schedulers",
      url: "https://github.com/pointfreeco/combine-schedulers",
      .upToNextMajor(from: "0.5.3")
    ),
//    .package(
//      name: "xctest-dynamic-overlay",
//      url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git",
//      .upToNextMajor(from: "0.2.1")
//    )
  ],
  targets: [
    .target(
      name: "Sparkly",
      dependencies: ["SparklyClientLive", "SparklyCommands"]
    ),
    .target(
      name: "SparklyCommands",
      dependencies: ["SparklyClient"]
    ),
    .target(
      name: "SparklyClient",
      dependencies: [
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
//        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
      ]
    ),
    .target(
      name: "SparklyClientLive",
      dependencies: ["SparklyClient", "Sparkle"]
    ),
    .testTarget(
      name: "SparklyClientTests",
      dependencies: ["SparklyClient"]
    ),
  ]
)
