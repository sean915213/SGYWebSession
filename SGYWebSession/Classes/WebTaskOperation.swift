//
//  BWSTaskOperation.swift
//  TheGalaxy
//
//  Created by Sean Young on 10/7/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import UIKit
import SGYSwiftUtility

// Protocol *greatly* simplifies working w/ WebTaskOperation when deserialized types are unimportant
protocol WebOperation: class {
    var requestID: WebRequestID { get }
    var sessionTask: URLSessionTask? { get }
    func cancel()
    func cancelForUnauthorized()
}

class WebTaskOperation<T: WebResultProtocol> : AsyncOperation, WebOperation {

    // MARK: - Initialization

    init(urlSession session: URLSession, request: WebRequest) {
        urlSession = session
        taskRequest = request
//        urlRequest = request
//        requestID = id
        super.init()
    }
    
    // MARK: - Properties
    
    let urlSession: URLSession
    
    let taskRequest: WebRequest
//    let urlRequest: URLRequest
    
    
    var requestID: WebRequestID { return taskRequest.requestID }
    
    var requestObject: SerializableObject?
    
    private(set) var requestResult: T?
    
    var suspended: Bool = false {
        didSet {
            guard let task = sessionTask else { return }
            if suspended && task.state == .running { task.suspend() }
            else if !suspended && task.state == .suspended { task.resume() }
        }
    }
    
    private(set) var sessionTask: URLSessionTask?
    
    // MARK: - Methods
    
    override func main() {
        // Construct url request
        let urlRequest = constructUrlRequest()
        
        // If request object exists deserialize
        if let payload = requestObject {
            do {
                let payloadData = try payload.JSONData()
                // Assign an upload task
                sessionTask = urlSession.uploadTask(with: urlRequest, from: payloadData, completionHandler: parseTaskResponse)
            } catch let error {
                // Create error result and complete execution
                let result = T(status: .serializationFailed(error), response: nil)
                endExecution(result)
                return
            }
        } else {
            // Use data task
            sessionTask = urlSession.dataTask(with: urlRequest, completionHandler: parseTaskResponse)
        }
        
        // If not suspended begin the task
        if !suspended { sessionTask!.resume() }
    }
    
    private func constructUrlRequest() -> URLRequest {
        // Create a mutable url request
        var urlRequest = URLRequest(url: taskRequest.url)
        // Assign method
        urlRequest.httpMethod = taskRequest.method.rawValue
        // Add additional headers
        taskRequest.additionalHeaders?.forEach { urlRequest.setValue($0.1, forHTTPHeaderField: $0.0) }
        
        return urlRequest
    }
    
    func cancelForUnauthorized() {
        // Assign unauthorized result
        requestResult = T(status: .notAuthorized, response: nil)
        // Call super's cancel only.  Task will be cancelled in a different manner.
        super.cancel()
    }
    
    override func cancel() {
        sessionTask?.cancel()
        super.cancel()
    }
    
    func endExecution(_ result: T) {
        requestResult = result
        super.endExecution()
    }
    
    private func parseTaskResponse(_ data: Data?, response: URLResponse?, error: Error?) {
        // CANCEL CHECK
        guard !isCancelled else {
            // If we haven't assigned a result then assign cancelled
            if requestResult == nil { requestResult = T(status: .cancelled, response: nil) }
            endExecution()
            return
        }
        
        // Check for error
        if let error = error {
            // Variable to hold resulting status
            var status: WebResultStatus
            // End execution before returning
            defer { endExecution(T(status: status, response: response as? HTTPURLResponse)) }
            
            // If not a known URLTask error code then assign as other
            guard let code = (error as NSError?)?.code, let urlError = URLTaskNSErrorCode(rawValue: code) else {
                status = .otherError(error)
                return
            }
            // Switch on error
            switch urlError {
            case .cancelled: status = .cancelled
            case .connectionTimedOut: status = .timedOut
            case .cannotConnectToHost: status = .timedOut
            case .connectionUnavailable: status = .connectionUnavailable
            case .lostConnection: status = .connectionLost
            }
            return
        }
        
        // If we don't have an error we should have a response and valid code or something weird happened
        guard let response = response as? HTTPURLResponse, let code = HTTPStatusCode(rawValue: response.statusCode) else {
            endExecution(T(status: .unknownError, response: nil))
            return
        }
        
        // Determine status
        var status = WebResultStatus.ok
        // Not okay if code >= 400 (client error + server error domain)
        if code.rawValue >= 400 {
            status = code.rawValue >= 500 ? .serverError(code) : .clientError(code)
        }
        
        // Create result
        var result = T(status: status, response: response)
        // End execution with this result when we return
        defer { endExecution(result) }
        
        // If no data return
        guard let data = data, !data.isEmpty else { return }
        // Assign data
        result.responseData = data
        
        // TODO: Expand protocol to include deserialization from other mime-types
        // Check whether mime-type is JSON (only supported)
        guard result.mimeType == .json else { return }
        
        // Try deserialization
        do {
            switch status {
            case .ok:
                // Into expected response class
                result.typedPayload = try T.ExpectedPayload.fromJSONData(data)
            default:
                // Into error response class
                result.typedError = try T.ErrorPayload.fromJSONData(data)
            }
        } catch let error {
            // TODO: Should this, all other things being successful, return failure simply for deserialization?
            result = T(status: .deserializationFailed(error), response: response)
        }
    }
}
