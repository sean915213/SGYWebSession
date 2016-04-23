//
//  BaseServiceWebSession.swift
//  JarusInsuranceApp
//
//  Created by Sean G Young on 12/13/14.
//  Copyright (c) 2014 Jarus Technologies. All rights reserved.
//

import Foundation
import UIKit
import SGYSwiftUtility

// MARK: - Web Related Enumerations

enum HTTPVerb : String, CustomStringConvertible {
    case DELETE = "DELETE", GET = "GET", POST = "POST", PUT = "PUT"
    
    var description: String { return rawValue }
}

enum HTTPHeader : String, CustomStringConvertible {
    case Authorization = "Authorization",
    AcceptContentType = "Accept",
    RequestContentType = "Content-Type"
    
    var description: String { return rawValue }
}

// Enum with mimetypes
enum MimeType: String, CustomStringConvertible {
    case HTML = "text/html",
    JSON = "application/json",
    PDF = "application/pdf"
    
    var description: String { return rawValue }
}

// MARK: - Class Implementation

@objc(BaseWebSession)
class BaseWebSession: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {
    
    // MARK: Static Properties
    
    // Tracks the global number of active tasks
    private static var numActiveTasks: Int = 0
    
    // MARK: Class Methods
    
    class func defaultJSONSessionConfiguration() -> NSURLSessionConfiguration {
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
    
    init(callbackQueue: NSOperationQueue, sessionConfig: NSURLSessionConfiguration) {
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
    
    // An instance for logging.
    lazy var logger: Logger = {
        let logger = Logger(contextDescription: NSStringFromClass(self.dynamicType.self))
        return logger
    }()
    
    // The QoS for our request operations
    var qualityOfService: NSQualityOfService = .Background {
        didSet { operationQueue.qualityOfService = qualityOfService }
    }
    
    // MARK: - Methods
    // MARK: Public Methods
    
    func invalidateAndCancel() {
        cancelAllTasks()
        urlSession.invalidateAndCancel()
    }
    
    func cancelAllTasks() {
        // Decrement active tasks for each operation
        for operation in operationQueue.operations {
            BaseWebSession.incrementActiveTasks(false)
            operation.cancel()
        }
    }
    
    func cancelTask(taskId: String) -> Bool {
        // Attempt finding operation with the provided taskId
        guard let taskOperation = operationQueue.operations.find({ $0.name == taskId }) else { return false }
        // Cancel and return
        taskOperation.cancel()
        return true
    }
    
    func reserveTaskId() -> String {
        return NSUUID().UUIDString
    }
    
    func beginRequest<T, U>(request: BWSTaskRequest<T, U>) -> String {
        // Reserve an id for this task
        let taskId = reserveTaskId()
        // Begin task
        beginRequest(request, reservedId: taskId)
        return taskId
    }
    
    func beginRequest<T, U>(request: BWSTaskRequest<T, U>, reservedId: String) {
        // Construct url request
        let urlRequest = constructUrlRequest(request)
        
        // If there's a request object must use an upload task, otherwise use a data task
        let operation: BWSTaskOperation<T, U> = BWSTaskOperation<T, U>(urlSession: urlSession, urlRequest: urlRequest)
        
        // Assign id to task as name
        operation.name = reservedId
        
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
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

        NSLog("UNAUTHORIZED HEARD IN SESSION")
        
        // Find all operations and cancel due to challenge
        for operation in operationQueue.operations {
            guard let bwsOperation = operation as? BWSOperation else { continue }
            bwsOperation.cancelForUnauthorized()
        }
        
        // Cancel challenge
        completionHandler(.CancelAuthenticationChallenge, nil)
    }
    
    // MARK: NSURLSessionTaskDelegate Implementation
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        NSLog("UNAUTHORIZED HEARD IN TASK")
        
        // Find the relevant operation and cancel it for unauthorized
        for operation in operationQueue.operations {
            guard let bwsOperation = operation as? BWSOperation where bwsOperation.sessionTask == task else { continue }
            bwsOperation.cancelForUnauthorized()
            break
        }

        // Cancel challenge.
        completionHandler(.CancelAuthenticationChallenge, nil)
    }
}