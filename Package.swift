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
            path: ".",
            exclude: [
                "Examples",
                "README.md",
                "FEATURES.md",
                "ARCHITECTURE.md",
                "COMPILATION.md",
                "SUMMARY.md",
                "STATUS.md",
                "FINAL_REPORT.md",
                "ISSUES_FOUND.md",
                "FIXES.md",
                "build.sh",
                "compile_check.sh",
                "validate.swift",
                ".git"
            ]
        )
    ]
)
