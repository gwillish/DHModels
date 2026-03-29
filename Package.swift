// swift-tools-version: 6.2

import PackageDescription

let sharedSettings: [SwiftSetting] = [
  .swiftLanguageMode(.v6),
  .enableUpcomingFeature("MemberImportVisibility"),
]

let products: [Product] = [
  .library(name: "DHModels", targets: ["DHModels"]),
  .library(name: "DHKit", targets: ["DHKit"]),
  .executable(name: "validate-dhpack", targets: ["validate-dhpack"]),
]

let targets: [Target] = [
  // Pure Codable value types — no Apple-only imports, compiles on Linux.
  .target(
    name: "DHModels",
    swiftSettings: sharedSettings
  ),

  // Observable stores + SRD bundle resources.
  .target(
    name: "DHKit",
    dependencies: [
      "DHModels",
      .product(name: "Logging", package: "swift-log"),
    ],
    resources: [
      .copy("Resources/adversaries.json"),
      .copy("Resources/environments.json"),
    ],
    swiftSettings: sharedSettings + [.defaultIsolation(MainActor.self)]
  ),

  // CLI tool for validating .dhpack files — depends only on DHModels.
  .executableTarget(
    name: "validate-dhpack",
    dependencies: [
      "DHModels",
      .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ],
    swiftSettings: sharedSettings
  ),

  // Tests for DHModels — run on Linux in CI.
  .testTarget(
    name: "DHModelsTests",
    dependencies: ["DHModels"],
    resources: [.copy("Fixtures")],
    swiftSettings: sharedSettings
  ),

  // Tests for DHKit.
  .testTarget(
    name: "DHKitTests",
    dependencies: ["DHKit"],
    swiftSettings: sharedSettings + [.defaultIsolation(MainActor.self)]
  ),
]

let package = Package(
  name: "DHModels",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .tvOS(.v17),
    .watchOS(.v10),
  ],
  products: products,
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
  ],
  targets: targets
)
