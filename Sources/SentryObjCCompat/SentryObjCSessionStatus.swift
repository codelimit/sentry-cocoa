// swiftlint:disable missing_docs
#if SWIFT_PACKAGE
internal import SentrySwift
#else
internal import Sentry
#endif
import Foundation

@objc public enum SentryObjCSessionStatus: Int {
    case ok = 0, exited, crashed, abnormal, unhandled
}

extension SentryObjCSessionStatus {
    init(_ underlying: SentrySessionStatus) {
        self = SentryObjCSessionStatus(rawValue: underlying.rawValue) ?? .ok
    }
    var underlying: SentrySessionStatus {
        SentrySessionStatus(rawValue: rawValue) ?? .ok
    }
}

// swiftlint:enable missing_docs
