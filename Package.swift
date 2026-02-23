// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Speakboard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Speakboard", targets: ["Speakboard"])
    ],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.7.9")
    ],
    targets: [
        .executableTarget(
            name: "Speakboard",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio")
            ]
        )
    ]
)
