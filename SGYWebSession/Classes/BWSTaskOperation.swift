//
//  BWSTaskOperation.swift
//  TheGalaxy
//
//  Created by Sean Young on 10/7/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import UIKit
import SGYSwiftUtility

// Protocol *greatly* simplifies working w/ BWSTaskOperation when deserialized types are unimportant
protocol BWSOperation: class {
    var sessionTask: NSURLSessionTask? { get }
    func cancelForUnauthorized()
}

class BWSTaskOperation<T: BWSJSONDeserializableObject, U: BWSJSONDeserializableObject> : AsyncOperation, BWSOperation {

    // MARK: - Initialization

    init(urlSession session: NSURLSession, urlRequest request: NSURLRequest) {
        urlSession = session
        urlRequest = request
        super.init()
    }
    
    // MARK: - Properties
    
    let urlSession: NSURLSession
    let urlRequest: NSURLRequest
    var requestObject: BWSJSONSerializableObject?
    
    private(set) var requestResult: BWSRequestResult<T, U>?
    
    var suspended: Bool = false {
        didSet {
            guard let task = sessionTask else { return }
            if suspended && task.state == .Running { task.suspend() }
            else if !suspended && task.state == .Suspended { task.resume() }
        }
    }
    
    private(set) var sessionTask: NSURLSessionTask?
    
    // MARK: - Methods
    
    override func main() {
        // If request object exists deserialize
        if let payload = requestObject {
            do {
                let payloadData = try payload.JSONData()
                // Assign an upload task
                sessionTask = urlSession.uploadTaskWithRequest(urlRequest, fromData: payloadData, completionHandler: parseTaskResponse)
            } catch let error as NSError {
                // Create error result and complete execution
                let result = BWSRequestResult<T, U>(response: nil, error: error, status: .RequestSerializationFailed)
                endExecution(result)
                return
            }
        } else {
            // Use data task
            sessionTask = urlSession.dataTaskWithRequest(urlRequest, completionHandler: parseTaskResponse)
        }
        
        // If not suspended begin the task
        if !suspended { sessionTask!.resume() }
    }
    
    func cancelForUnauthorized() {
        // Assign unauthorized result
        requestResult = BWSRequestResult(status: .NotAuthorized)
        // Call super's cancel only.  Task will be cancelled in a different manner.
        super.cancel()
    }
    
    override func cancel() {
        sessionTask?.cancel()
        super.cancel()
    }
    
    func endExecution(result: BWSRequestResult<T, U>) {
        requestResult = result
        super.endExecution()
    }
    
    private func parseTaskResponse(data: NSData?, response: NSURLResponse?, error: NSError?) {
        // CANCEL CHECK
        guard !cancelled else {
            // If we haven't assigned a result then assign cancelled
            if requestResult == nil { requestResult = BWSRequestResult(status: .Cancelled) }
            endExecution()
            return
        }
        
        // Check for error
        if let error = error {
            endExecution(BWSRequestResult(error: error))
            return
        }
        
        // If we don't have an error we should have a response or something weird happened
        guard let response = response else {
            endExecution(BWSRequestResult(status: .OtherError))
            return
        }
        
        // Create result
        var result = BWSRequestResult<T, U>(response: response)
        // If no data return
        guard let data = data where data.length > 0 else {
            endExecution(result)
            return
        }
        
        // Try deserialization
        do {
            // If status is >= 400 then payload is an error so use that type instead
            if result.responseCode?.rawValue >= 400 {
                result.typedError = try U.fromJSONData(data)
            } else {
                // Create instance from payload
                result.typedPayload = try T.fromJSONData(data)
            }
        } catch let error as NSError {
            // Replace result with error
            result = BWSRequestResult<T, U>(response: response, error: error, status: .ResponseDeserializationFailed)
        }
        
        // Complete execution
        endExecution(result)
    }
}
