// https://developer.apple.com/forums/thread/729335

import Foundation
import UIKit
import os.log

fileprivate let logger = Logger(category: "QRunInBackgroundAssertion")

/// Prevents the process from suspending by holding a `UIApplication` background
/// task assertion.
///
/// The assertion is released if:
///
/// * You explicitly release the assertion by calling ``release()``.
/// * There are no more strong references to the object and so it gets deinitialised.
/// * The system ‘calls in’ the assertion, in which case it calls the
///   ``systemDidReleaseAssertion`` closure, if set.
///
/// You should aim to explicitly release the assertion yourself, as soon as
/// you’ve completed the work that the assertion covers.

final class QRunInBackgroundAssertion {
    
    /// The name used when creating the assertion.

    let name: String
    
    /// Called when the system releases the assertion itself.
    ///
    /// This is called on the main thread.
    ///
    /// To help avoid retain cycles, the object sets this to `nil` whenever the
    /// assertion is released.

    var systemDidReleaseAssertion: (() -> Void)? /*{
        willSet { dispatchPrecondition(condition: .onQueue(.main)) }
    }*/

    private var taskID: UIBackgroundTaskIdentifier
    
    /// Creates an assertion with the given name.
    ///
    /// The name isn’t used by the system but it does show up in various logs so
    /// it’s important to choose one that’s meaningful to you.
    ///
    /// Must be called on the main thread.

    init(name: String) {
        // dispatchPrecondition(condition: .onQueue(.main))
        self.name = name
        self.systemDidReleaseAssertion = nil
        // Have to initialise `taskID` first so that I can capture a fully
        // initialised `self` in the expiration handler.  If the expiration
        // handler ran ／before／ I got a chance to set `self.taskID` to `t`,
        // things would end badly.  However, that can’t happen because I’m
        // running on the main thread — courtesy of the Dispatch precondition
        // above — and the expiration handler also runs on the main thread.
        self.taskID = .invalid
        let t = UIApplication.shared.beginBackgroundTask(withName: name) {
            self.taskDidExpire()
        }
        self.taskID = t
        logger.info("Started: \(name)")
    }
    
    /// Release the assertion.
    ///
    /// It’s safe to call this redundantly, that is, call it twice in a row or
    /// call it on an assertion that’s expired.
    ///
    /// Must be called on the main thread.

    func release() {
        // dispatchPrecondition(condition: .onQueue(.main))
        self.consumeValidTaskID { _ in }
        logger.info("Released: \(self.name)")
    }
    
    deinit {
        // We don’t apply this assert because it’s hard to force the last object
        // reference to be released on the main thread.  However, it should be
        // safe to call through to `consumeValidTaskID(_:)` because no other
        // thread can be running inside this object (because that would have its
        // own retain on us).
        //
        // dispatchPrecondition(condition: .onQueue(.main))
        self.consumeValidTaskID { _ in }
        logger.info("Deinit: \(self.name)")
    }
    
    private func consumeValidTaskID(_ body: (UIBackgroundTaskIdentifier) -> Void) {
        // Move this check to all clients except the deinitialiser.
        //
        // dispatchPrecondition(condition: .onQueue(.main))
        guard self.taskID != .invalid else { return }
        logger.info("Consuming: \(self.name)")
        let t = self.taskID
        self.taskID = .invalid
        body(t)
        UIApplication.shared.endBackgroundTask(t)
        self.systemDidReleaseAssertion = nil
        logger.info("Done: \(self.name)")
    }
    
    private func taskDidExpire() {
        logger.info("TaskDidExpire: \(self.name)")
        // dispatchPrecondition(condition: .onQueue(.main))
        self.consumeValidTaskID() { t in
            self.systemDidReleaseAssertion?()
        }
    }
}
