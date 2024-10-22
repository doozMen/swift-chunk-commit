// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let lib = "ChunkCommiter"
let executable = "chunk-commit"

let package = Package(
  name: "swift-chunk-commit",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: lib, targets: [lib]),
    .executable(name: executable, targets: [executable]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    .package(url: "https://github.com/doozMen/swift-cli-logger.git", branch: "1.0.1"),
  ],
  targets: [
    .target(
      name: lib,
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "ClILogger", package: "swift-cli-logger"),
      ]),
    .executableTarget(
      name: executable,
      dependencies: [
        .target(name: lib)
      ]),
  ]
)
