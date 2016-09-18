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
open class WebSession: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    // MARK: Static Properties
    
    // Tracks the global number of active tasks
    private static var numActiveTasks: Int = 0
    
    // MARK: Class Methods
    
    public class func defaultJSONSessionConfiguration() -> URLSessionConfiguration {
        var jsonHeaders = [String : Any]()
        jsonHeaders[HTTPHeader.acceptContentType.rawValue] = MimeType.json.rawValue
        jsonHeaders[HTTPHeader.requestContentType.rawValue] = MimeType.json.rawValue
        
        let jsonConfig = URLSessionConfiguration.default
        jsonConfig.httpAdditionalHeaders = jsonHeaders
        
        return jsonConfig
    }
    
    private class func incrementActiveTasks(_ increment: Bool) {
        // Do this within the main queue in-order to serialize properly
        DispatchQueue.main.async { () -> Void in
            self.numActiveTasks += increment ? 1 : -1
            UIApplication.shared.isNetworkActivityIndicatorVisible = self.numActiveTasks > 0
        }
    }
    
    // MARK: Initialization
    
    public init(callbackQueue: OperationQueue, sessionConfig: URLSessionConfiguration) {
        self.callbackQueue = callbackQueue
        super.init()
        urlSession = Foundation.URLSession(configuration: sessionConfig, delegate: self, delegateQueue: operationQueue)
    }
    
    deinit {
        // TODO: Is this still required?  I don't think we can deinit without this having happened.
        // Cancel our session object
        urlSession.invalidateAndCancel()
        // We should not be allowed to deallocate with active tasks in our queue.  But if we are, then cancel all tasks and print a warning.
        guard !operationQueue.operations.isEmpty else { return }
        logger.log("Deallocating with \(operationQueue.operationCount) operation(s) in queue.  They will be canceled.", level: .warning)
        // Cancel
        cancelAllRequests()
    }
    
    // MARK: Properties
    
    // Queue used for all callbacks
    private let callbackQueue: OperationQueue
    
    // Our url session object
    private var urlSession: URLSession!
    
    // Operation queue for all our internal tasks
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = NSStringFromClass(type(of: self).self) + "Queue"
        return queue
    }()
    
    // List of task operations
    private var taskOperations: [WebOperation] {
        return operationQueue.operations.typeOf()
    }
    
    // An instance for logging.
    private lazy var logger: Logger = {
        let logger = Logger(sourceName: NSStringFromClass(type(of: self).self))
        return logger
    }()
    
    // MARK: - Methods
    // MARK: Public Methods
    
    public func invalidateAndCancel() {
        cancelAllRequests()
        urlSession.invalidateAndCancel()
    }
    
    public func cancelAllRequests() {
        // Cancel all task operations
        taskOperations.forEach { $0.cancel() }
    }
    
    public func cancelRequest(withID requestID: WebRequestID) -> Bool {
        // Attempt finding operation with the provided taskId
        guard let operation = operationQueue.operations.find(predicate: { ($0 as! WebOperation).requestID == requestID }) else {
            return false
        }
        // Cancel and return
        operation.cancel()
        return true
    }
    
    public func begin<T: WebResultProtocol>(request: WebRequest, completed: ((T) -> Void)?) {
        // Construct url request
//        let urlRequest = constructUrlRequest(request)
        
        // If there's a request object must use an upload task, otherwise use a data task
        let operation = WebTaskOperation<T>(urlSession: urlSession, request: request)
        
        // Assign object for request body
        operation.requestObject = request.requestObject
        
        // Begin execution
        start(operation: operation, toggleActivity: request.displayNetworkActivity) {
            completed?(operation.requestResult!)
        }
    }

//    public func begin<T: DeserializableObject, U: DeserializableObject>(request: WebRequest, completed: ((WebResult<T, U>) -> Void)?) {
//        // Construct url request
//        let urlRequest = constructUrlRequest(request)
//        
//        // If there's a request object must use an upload task, otherwise use a data task
//        let operation: WebTaskOperation<T, U> = WebTaskOperation<T, U>(urlSession: urlSession, urlRequest: urlRequest, requestID: request.requestID)
//        
//        // Assign object for request body
//        operation.requestObject = request.requestObject
//        
//        // Begin execution
//        start(operation: operation, toggleActivity: request.displayNetworkActivity) {
//            completed?(operation.requestResult!)
//        }
//    }
    
    // MARK: Private Methods
    
//    private func constructUrlRequest(_ taskRequest: WebRequest) -> URLRequest {
//        // Create a mutable url request
//        var urlRequest = URLRequest(url: taskRequest.url)
//        // Assign method
//        urlRequest.httpMethod = taskRequest.method.rawValue
//        // Add additional headers
//        taskRequest.additionalHeaders?.forEach { urlRequest.setValue($0.1, forHTTPHeaderField: $0.0) }
//        
//        return urlRequest
//    }
    
    private func start<T>(operation: WebTaskOperation<T>, toggleActivity: Bool,  completionBlock: (() -> Void)?) {
        // Create a callback operation to fire when completed
        let callbackOperation = BlockOperation {
            // Execute completion block
            completionBlock?()
            // If used indicator then decrement active tasks
            if toggleActivity { WebSession.incrementActiveTasks(false) }
        }
        // Add main operation as dependancy
        callbackOperation.addDependency(operation)
        
        // Add operations to their respective queues
        callbackQueue.addOperation(callbackOperation)
        operationQueue.addOperation(operation)
        
        // Update our active network state
        if toggleActivity { WebSession.incrementActiveTasks(true) }
    }
    
    // MARK: NSURLSessionDelegate Implementation
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Cancel all operations
        taskOperations.forEach { $0.cancelForUnauthorized() }
        // Cancel challenge
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
    
    // MARK: NSURLSessionTaskDelegate Implementation
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Find the relevant operation and cancel.  
        // It's possible it does not exist in rare circumstances where, for example, it was canceled immediately after receiving this challenge.
        taskOperations.find(predicate: { $0.sessionTask == task })?.cancelForUnauthorized()
        // Cancel challenge
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
