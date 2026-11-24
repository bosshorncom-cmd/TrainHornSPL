// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TrainHornSPL",
    products: [
        .library(name: "TrainHornSPL", targets: ["TrainHornSPL"]),
        .executable(name: "train-horn-spl", targets: ["train-horn-spl"]),
    ],
    targets: [
        .target(name: "TrainHornSPL"),
        .executableTarget(name: "train-horn-spl", dependencies: ["TrainHornSPL"]),
        .testTarget(name: "TrainHornSPLTests", dependencies: ["TrainHornSPL"]),
    ]
)
