// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SwiftZip",
    targets: [
        Target(name: "SwiftZip", dependencies: ["Cminizip"])
    ]
)
