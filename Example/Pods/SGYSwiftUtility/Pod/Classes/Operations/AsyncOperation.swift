//
//  AsyncOperation.swift
//
//  Created by Sean G Young on 3/30/16.
//  Copyright © 2016 Sean G Young. All rights reserved.

import Foundation

public class AsyncOperation: SGYOperation {
    
    // MARK: Required NSOperation properties to support asynchronous execution

    // Indicates we do not finish when `main` exits.  Does not matter when used in an NSOperationQueue (as this generally will be), but this declaration ensures this operation works as intended outside a queue.
    public override var asynchronous: Bool { return true }
    
    private var _executing: Bool = false
    // `NSOperation` documentation indicates this property must be overrided and emmit KVO notifications. Marking dynamic emits a notification for `executing`.  It does not emit for `isExecuting`, which the documentation suggests is required.
    // NOTE: In my testing the behavior of this class in an `NSOperationQueue` is not affected by the value of this property at all.
    public override dynamic var executing: Bool {
        get { return _executing }
        set { _executing = newValue }
    }
    
    private var _finished: Bool = false
    // `NSOperation` documentation indicates this property must be overrided and emmit KVO notifications. Marking dynamic emits a notification for "finished".  It does not emit for `isFinished`, which the documentation suggests is required.
    // NOTE: In my testing the behavior of this class in an `NSOperationQueue` is not affected by KVO notifications at all.
    // NOTE: In my testing this property alone completely determines whether dependent operations and `completionBlock:` are fired.  Also determines whether `NSOperationQueue` considers the operation completed and removes from queue.
    public override dynamic var finished: Bool {
        get { return _finished }
        set { _finished = newValue }
    }
    
    // MARK: Methods
    
    public override func start() {
        // Cancel check
        guard !cancelled else {
            endExecution()
            return
        }
        
        // Toggle executing
        executing = true
        // Run main
        main()
    }
    
    // Required properties to set in order to indicate completion of operation
    public func endExecution() {
        executing = false
        finished = true
    }
}
