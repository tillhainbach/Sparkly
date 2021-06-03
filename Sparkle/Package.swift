// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "Sparkle",
  platforms: [.macOS(.v10_11)],
  products: [
    .library(
      name: "Sparkle",
      targets: ["Sparkle"]
    ),
    .library(
      name: "SparkleCore",
      targets: ["SparkleCore"]
    ),
  ],
  targets: [
    .binaryTarget(
      name: "Sparkle",
      path: "./Sparkle.xcframework"
    ),
    .binaryTarget(
      name: "SparkleCore",
      path: "./SparkleCore.xcframework"
    ),
  ]
)
