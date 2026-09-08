// swift-tools-version:6.0
// Proof-of-concept: call the Sentry Cocoa SDK from *pure* C++ using
// Swift <-> C++ interoperability (`-cxx-interoperability-mode=default`).
//
// The Sentry public API (`SentrySDK`, `SentryOptions`, ...) is `@objc` /
// Foundation based and is therefore NOT projected into a callable C++ form by
// the Swift -> C++ header generator. To bridge the gap we add a tiny Swift
// "shim" module (`sentry`) that imports the SDK and re-exposes a handful of
// free functions using only interop-friendly signatures (`const char *`).
//
// When compiled with C++ interoperability enabled, SwiftPM emits a generated
// header (`sentry-Swift.h`) that projects the `sentry` module into the C++
// `sentry` namespace, so a plain `.cpp` file can `#include` it and call
// `sentry::init(...)` / `sentry::shutdown()` directly.

import PackageDescription

let package = Package(
    name: "macOS-SPM-CppInterop",
    platforms: [.macOS(.v12)],
    dependencies: [
        // Depend on the local checkout of sentry-cocoa. We use the prebuilt
        // binary `Sentry` product on purpose: the shim only needs the SDK's
        // Objective-C/Swift API, and enabling C++ interop on the *shim* module
        // does not require the SDK itself to be built with interop.
        .package(name: "Sentry", path: "../../../sentry-cocoa")
    ],
    targets: [
        // Swift shim compiled with C++ interoperability. Because the module is
        // named `sentry`, its free functions are projected into the C++
        // `sentry::` namespace.
        .target(
            name: "sentry",
            dependencies: [
                .product(name: "Sentry", package: "Sentry")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        // Pure C++ executable. It depends on the `sentry` shim, includes the
        // generated `sentry-Swift.h`, and calls the SDK from a `.cpp` file with
        // no Objective-C anywhere.
        .executableTarget(
            name: "SentryCppExample",
            dependencies: ["sentry"],
            swiftSettings: [
                // Required so SwiftPM passes `-cxx-interoperability-mode=default`
                // when consuming the interop-enabled `sentry` module.
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
