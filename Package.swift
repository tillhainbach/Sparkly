// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Sparkly",
  platforms: [.macOS(.v11)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
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
    // Dependencies declare other packages that this package depends on.
    .package(name: "Sparkle", url: "https://github.com/sparkle-project/Sparkle", .branch("2.x"))
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
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
      dependencies: []
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
