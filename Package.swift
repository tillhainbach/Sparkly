// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Sparkly",
  platforms: [.macOS(.v11)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "SparklyCommands",
      targets: ["SparklyCommands"]),
    .library(
      name: "SUUpdaterClient",
      targets: ["SUUpdaterClient"]),
    .library(
      name: "SUUpdaterClientLive",
      targets: ["SUUpdaterClientLive"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(path: "./Sparkle")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "SparklyCommands",
      dependencies: []
    ),
    .target(
      name: "SUUpdaterClient",
      dependencies: []
    ),
    .target(
      name: "SUUpdaterClientLive",
      dependencies: ["Sparkle"]
    ),
    .testTarget(
      name: "SUUpdaterClientTests",
      dependencies: []),
  ]
)
