// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DTFoundation",
    platforms: [
        .iOS(.v9),         //.v8 - .v13
        .macOS(.v10_10),    //.v10_10 - .v10_15
        .tvOS(.v9),        //.v9 - .v13
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "DTFoundation",
            targets: ["DTFoundation"]),
    ],
    targets: [
        .target(
            name: "DTFoundation",
            dependencies: [],
            path: "Core",
			exclude: ["DTFoundation-Info.plist", "DTFoundation-Prefix.pch"],
            cSettings: [
                .headerSearchPath("include/DTFoundation"),
                .headerSearchPath("Source/Externals/minizip"),
            ]
        ),
        .testTarget(
            name: "DTFoundationTests",
            dependencies: ["DTFoundation"],
            path: "Test",
			exclude: ["UnitTests-Info.plist", "UnitTests-Prefix.pch"],
			resources: [.copy("SelfSigned.der"),
				.copy("Resources/zipContent/Franz.txt"),
				.copy("Resources/zipContent/Oliver.txt"),
				.copy("Resources/zipContent/Stefan.txt"),
				.copy("Resources/gzip_sample.txt.original"),
				.copy("Resources/gzip_sample.txt-z"),
				.copy("Resources/zipContent/Rene"),
				.copy("Resources/gzip_sample.txt.gz"),
				.copy("Resources/gzip_sample_invalid.gz"),
				.copy("Resources/gzip_sample.txt.foo"),
				.copy("Resources/processing_instruction.html"),
				.copy("Resources/gzip_sample.txt-gz"),
				.copy("Resources/html_doctype.html"),
				.copy("Resources/DictionarySample.plist"),
				.copy("Resources/ArraySample.plist"),
				.copy("Resources/screenshot.png"),
				.copy("Resources/sample.zip"),
				.copy("Resources/SelfSigned.der")
			],
            cSettings: [
                .headerSearchPath("include"),
            ]
        )
    ]
)
