# macOS-SPM-CppInterop — pure C++ ➜ Sentry (proof of concept)

This sample is a **proof of concept** showing how a *pure C++* program can drive
the Sentry Cocoa SDK — calling `sentry::init(...)` and `sentry::shutdown()`
directly from a `.cpp` file, with **no Objective-C, no `.mm`, and no `@import`**.

> ⚠️ **Status: experimental / not officially supported.**
> This uses Swift ↔ C++ interoperability (`-cxx-interoperability-mode=default`)
> and is intended to demonstrate feasibility, not as a supported integration
> path. The supported way to use the SDK from C++ today is the Objective-C++
> (`.mm`) bridge (`#import <Sentry/Sentry.h>` + `<Sentry/Sentry-Swift.h>`).
> This is macOS-only and must be built with a recent Swift toolchain (Xcode 16+).

## Why a shim is needed

The Sentry public API (`SentrySDK`, `SentryOptions`, `SentryHub`, ...) is
`@objc` / `NSObject` / Foundation based. The Swift → C++ header generator does
**not** project that Objective-C-flavored API into a callable C++ form (it deals
in `NSString *`, Objective-C blocks, `Date`, `[String: Any]`, etc.).

So we can't `#include` the SDK directly from C++. Instead we add a tiny Swift
**shim module** (named `sentry`) that:

1. `import`s the SDK (`import Sentry`), and
2. re-exposes a few `public` free functions using only **interop-friendly**
   signatures (`UnsafePointer<CChar>` ➜ `const char *`).

Because the shim is compiled with C++ interoperability enabled and the module is
named `sentry`, SwiftPM emits a generated header (`sentry-Swift.h`) that projects
those functions into the C++ **`sentry::`** namespace. A plain `.cpp` file then
includes that header and calls them.

```
main.cpp  ──includes──►  sentry-Swift.h  ──projects──►  sentry (Swift shim)  ──imports──►  Sentry SDK
 (pure C++)              (generated)                     (-cxx-interop)                    (@objc/Swift)
```

## Layout

```
macOS-SPM-CppInterop/
├── Package.swift                        # SwiftPM manifest (2 targets)
├── Sources/
│   ├── sentry/SentryCxx.swift           # Swift shim → C++ `sentry::` namespace
│   └── SentryCppExample/main.cpp        # pure C++ entry point
└── README.md
```

- `sentry` — Swift shim target, built with `.interoperabilityMode(.Cxx)`. Exposes
  `sentry::init`, `sentry::shutdown`, `sentry::captureMessage`.
- `SentryCppExample` — pure C++ executable target that depends on `sentry`.

The package depends on the local `sentry-cocoa` checkout
(`.package(name: "Sentry", path: "../../../sentry-cocoa")`) and links the
prebuilt binary `Sentry` product. Only the *shim* needs C++ interop; the SDK
itself does not have to be built with interop, since the shim consumes its
ordinary `@objc`/Swift API.

## Build & run

From this directory, on macOS with Xcode 16+ selected:

```bash
swift run SentryCppExample
```

Expected output:

```
[C++] Initializing Sentry from a pure C++ translation unit...
[C++] Capturing a test message...
[C++] Shutting Sentry down...
[C++] Done.
```

Replace the DSN in `main.cpp` with your own to see the event arrive in your
Sentry project.

## Notes, caveats & troubleshooting

- **Toolchain**: requires a Swift toolchain with mature C++ interop (Xcode 16+ /
  Swift 5.9+; this manifest targets `swift-tools-version:6.0`).
- **Generated header include path**: this sample uses
  `#include "sentry-Swift.h"`. Depending on the toolchain/SwiftPM version the
  generated header may instead be exposed as `<sentry/sentry-Swift.h>`. If the
  compiler can't find it, try that form. You can locate the generated header
  under `.build/` after a build:
  ```bash
  find .build -name 'sentry-Swift.h'
  ```
- **`init` naming**: `init` is a Swift keyword, so the shim declares it as
  `` func `init` ``. It still projects to a plain `sentry::init(...)` in C++.
  If your toolchain rejects the projected name, rename the shim function to e.g.
  `start` and call `sentry::start(...)`.
- **Case-insensitive filesystems**: the shim module is named `sentry`
  (lowercase) to yield the `sentry::` namespace, while the SDK module is `Sentry`
  (uppercase). Because `Sentry` is shipped as a prebuilt `binaryTarget` it isn't
  recompiled, so the two shouldn't collide. If you do hit a case-collision on
  APFS/HFS+, rename the shim target (e.g. to `SentryCpp`) — the namespace becomes
  `SentryCpp::` accordingly.
- **Only free functions / interop-friendly types** cross the boundary. To expose
  more of the SDK (breadcrumbs, tags, user, scope, ...), add more `public`
  wrapper functions to `SentryCxx.swift` using C-friendly parameter types.
