//
//  BaseWebSession.swift
//
//  Created by Sean G Young on 12/13/14.
//  Copyright © 2014 Sean G Young. All rights reserved.
//

import Foundation
import UIKit
import SGYSwiftUtility

// NOTE: NSObject inheritence is easy way to conform to  NSObjectProtocol required by NSURLSession delegation
public class BaseWebSession: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {
    
    // MARK: Static Properties
    
    // Tracks the global number of active tasks
    private static var numActiveTasks: Int = 0
    
    // MARK: Class Methods
    
    public class func defaultJSONSessionConfiguration() -> NSURLSessionConfiguration {
        var jsonHeaders = [NSObject : AnyObject]()
        jsonHeaders[HTTPHeader.AcceptContentType.rawValue] = MimeType.JSON.rawValue
        jsonHeaders[HTTPHeader.RequestContentType.rawValue] = MimeType.JSON.rawValue
        
        let jsonConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        jsonConfig.HTTPAdditionalHeaders = jsonHeaders
        
        return jsonConfig
    }
    
    private class func incrementActiveTasks(increment: Bool) {
        // Do this within the main queue in-order to serialize properly
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.numActiveTasks += (increment ? 1 : -1)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = (self.numActiveTasks > 0)
        }
    }
    
    // MARK: Initialization
    
    public init(callbackQueue: NSOperationQueue, sessionConfig: NSURLSessionConfiguration) {
        self.callbackQueue = callbackQueue
        super.init()
        urlSession = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: operationQueue)
    }
    
    deinit {
        // TODO: Is this still required?  I don't think we can deinit without this having happened.
        // Cancel our session object
        urlSession.invalidateAndCancel()
        // We should not be allowed to deallocate with active tasks in our queue.  But if we are, then cancel all tasks and print a warning.
        guard !operationQueue.operations.isEmpty else { return }
        logger.log("Deallocating with \(operationQueue.operationCount) operation(s) in queue.  They will be canceled.", level: .Warning)
        // Cancel
        cancelAllTasks()
    }
    
    // MARK: Properties
    
    // Queue used for all callbacks
    private let callbackQueue: NSOperationQueue
    
    // Our url session object
    private var urlSession: NSURLSession!
    
    // Internal count of operation ids
    private var nextOperationId: Int = 0
    
    // Operation queue for all our internal tasks
    private lazy var operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = NSStringFromClass(self.dynamicType.self) + "Queue"
        queue.qualityOfService = self.qualityOfService
        return queue
    }()
    
    // List of task operations
    private var taskOperations: [BWSOperation] {
        return operationQueue.operations.typeOf()
    }
    
    // An instance for logging.
    private lazy var logger: Logger = {
        let logger = Logger(contextDescription: NSStringFromClass(self.dynamicType.self))
        return logger
    }()
    
    // The QoS for our request operations
    public var qualityOfService: NSQualityOfService = .Background {
        didSet { operationQueue.qualityOfService = qualityOfService }
    }
    
    // MARK: - Methods
    // MARK: Public Methods
    
    public func invalidateAndCancel() {
        cancelAllTasks()
        urlSession.invalidateAndCancel()
    }
    
    public func cancelAllTasks() {
        // Cancel all task operations
        taskOperations.forEach { $0.cancel() }
    }
    
    public func cancelTask(taskId: String) -> Bool {
        // Attempt finding operation with the provided taskId
        guard let taskOperation = operationQueue.operations.find({ $0.name == taskId }) else {
            return false
        }
        // Cancel and return
        taskOperation.cancel()
        return true
    }
    
    public func reserveTaskId() -> String {
        return NSUUID().UUIDString
    }
    
    public func beginRequest<T, U>(request: BWSTaskRequest<T, U>) -> String {
        // Reserve an id for this task
        let taskId = reserveTaskId()
        // Begin task
        beginRequest(request, reservedId: taskId)
        return taskId
    }
    
    public func beginRequest<T, U>(request: BWSTaskRequest<T, U>, reservedId: String) {
        // Construct url request
        let urlRequest = constructUrlRequest(request)
        
        // If there's a request object must use an upload task, otherwise use a data task
        let operation: BWSTaskOperation<T, U> = BWSTaskOperation<T, U>(urlSession: urlSession, urlRequest: urlRequest)
        
        // Assign id to task as name
        operation.name = reservedId
        // Assign object for request body
        operation.requestObject = request.requestObject
        
        // Begin execution
        beginOperation(operation) { request.completedCallback?(result: operation.requestResult!) }
    }
    
    // MARK: Private Methods
    
    private func constructUrlRequest<T, U>(taskRequest: BWSTaskRequest<T, U>) -> NSMutableURLRequest {
        
        // Create a mutable url request
        let urlRequest = NSMutableURLRequest(URL: taskRequest.url)
        // Assign method
        urlRequest.HTTPMethod = taskRequest.method.rawValue
        
        // WORKAROUND: Bug in iOS 8.3 that causes the NSURLSessionConfiguration's HTTPAdditionalHeaders to NOT be properly sent with request.  So must merge them in here.
        // MUST do this before assigning additional headers from request because the session config is supposed to be over-written by more specific headers set on the request object.
//        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
//            if let configHeaders = urlSession.configuration.HTTPAdditionalHeaders as? [String: String] {
//                for (header, val) in configHeaders { urlRequest.setValue(val, forHTTPHeaderField: header) }
//            }
//        }
        
        // Add additional headers
        taskRequest.additionalHeaders?.forEach { urlRequest.setValue($0.1, forHTTPHeaderField: $0.0) }
        
        return urlRequest;
    }
    
    private func beginOperation<T, U>(operation: BWSTaskOperation<T, U>, completionBlock: (() -> Void)?) {
        // Create a callback operation to fire when completed
        let callbackOperation = NSBlockOperation {
            // Execute completion block
            completionBlock?()
            // Decrement the active tasks
            BaseWebSession.incrementActiveTasks(false)
        }
        // Add main operation as dependancy
        callbackOperation.addDependency(operation)
        
        // Add operations to their respective queues
        callbackQueue.addOperation(callbackOperation)
        operationQueue.addOperation(operation)
        
        // Update our active network state
        BaseWebSession.incrementActiveTasks(true)
    }
    
    // MARK: NSURLSessionDelegate Implementation
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        // Cancel all operations
        taskOperations.forEach { $0.cancelForUnauthorized() }
        // Cancel challenge
        completionHandler(.CancelAuthenticationChallenge, nil)
    }
    
    // MARK: NSURLSessionTaskDelegate Implementation
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        // Find the relevant operation and cancel.  
        // It's possible it does not exist in rare circumstances where, for example, it was canceled immediately after receiving this challenge.
        if let operation = taskOperations.find({ $0.sessionTask == task }) { operation.cancel() }
        // Cancel challenge
        completionHandler(.CancelAuthenticationChallenge, nil)
    }
}