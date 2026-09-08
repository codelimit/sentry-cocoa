import Foundation
import Sentry

// MARK: - Pure-C++ facade over the Sentry Cocoa SDK
//
// This file is compiled with `-cxx-interoperability-mode=default` (see
// Package.swift). Because this module is named `sentry`, every `public`
// free function below is projected into the C++ `sentry::` namespace and can
// be called from a plain `.cpp` translation unit via the generated
// `sentry-Swift.h` header.
//
// We deliberately restrict the signatures to interop-friendly types
// (`UnsafePointer<CChar>` -> `const char *`) so the C++ side never has to deal
// with `NSString`, Objective-C blocks, or Foundation types.

/// Initializes the Sentry SDK with the given DSN.
///
/// Mirrors `sentry_init` from sentry-native. Projected to C++ as
/// `sentry::init(const char *dsn)`.
///
/// - Parameter dsn: A null-terminated UTF-8 DSN string.
public func `init`(_ dsn: UnsafePointer<CChar>) {
    let dsnString = String(cString: dsn)
    SentrySDK.start { options in
        options.dsn = dsnString
        options.debug = true
    }
}

/// Flushes and shuts the Sentry SDK down.
///
/// Mirrors `sentry_shutdown` from sentry-native. Projected to C++ as
/// `sentry::shutdown()`.
public func shutdown() {
    SentrySDK.close()
}

/// Captures a simple message event and flushes it.
///
/// Convenience helper so the proof-of-concept has something observable to send.
/// Projected to C++ as `sentry::captureMessage(const char *message)`.
///
/// - Parameter message: A null-terminated UTF-8 message string.
public func captureMessage(_ message: UnsafePointer<CChar>) {
    SentrySDK.capture(message: String(cString: message))
    SentrySDK.flush(timeout: 5)
}
