// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "harness",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ObjCExceptionCatcher"),
        .target(
            name: "HarnessCore",
            dependencies: ["ObjCExceptionCatcher"],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .executableTarget(name: "harness", dependencies: ["HarnessCore"]),
        .testTarget(name: "HarnessCoreTests", dependencies: ["HarnessCore"]),
    ]
)
