// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeepDrivesAwake",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "KeepDrivesAwake", targets: ["KeepDrivesAwake"])
    ],
    targets: [
        .executableTarget(
            name: "KeepDrivesAwake",
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        )
    ]
)
