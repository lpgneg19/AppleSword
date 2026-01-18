// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AppleSword",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AppleSword", targets: ["AppleSword"])
    ],
    dependencies: [
        .package(url: "https://github.com/baptistecdr/Aria2Kit", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppleSword",
            dependencies: [
                "Aria2Kit"
            ],
            path: "AppleSword",
            resources: [
                .process("Assets.xcassets"),
                .process("Localizable.xcstrings"),
                .process("InfoPlist.xcstrings")
            ]
        )
    ]
)