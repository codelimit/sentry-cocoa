#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The status of a @c SentrySession.
 * @note The values @c SentryObjCSessionStatusOk to @c SentryObjCSessionStatusAbnormal match the
 * raw values of sentry-native's @c sentry_session_status_t.
 */
typedef NS_ENUM(NSInteger, SentryObjCSessionStatus) {
    /**
     * The session is in progress or ended without errors. When ending a session with this status,
     * the session ends as @c SentryObjCSessionStatusExited instead, or as
     * @c SentryObjCSessionStatusUnhandled when an unhandled error that didn't terminate the
     * process was recorded.
     */
    SentryObjCSessionStatusOk = 0,
    /// The session ended without errors.
    SentryObjCSessionStatusExited,
    /// The session ended because of a crash.
    SentryObjCSessionStatusCrashed,
    /// The session ended abnormally, for example because the app was terminated while the device
    /// was low on memory.
    SentryObjCSessionStatusAbnormal,
    /// The session ended because of an unhandled error that didn't terminate the process.
    SentryObjCSessionStatusUnhandled
};

NS_ASSUME_NONNULL_END
