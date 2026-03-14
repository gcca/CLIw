// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CLIw",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
    ],
    targets: [
        .executableTarget(
            name: "CLIw",
            path: "Sources/CLIw",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/CLIw/Info.plist"
                ])
            ]
        ),
    ]
)
