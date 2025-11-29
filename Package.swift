// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "KKNetwork",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "KKNetwork",
            targets: ["KKNetwork"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "KKNetwork",
            dependencies: [
                "Alamofire",
                "SwiftyJSON"
            ],
            path: "Sources"
        )
    ]
)
