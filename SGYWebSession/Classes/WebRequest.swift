//
//  WebRequest.swift
//
//  Created by Sean Young on 11/13/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import Foundation

//public class WebRequest2 {
//    
//    // MARK: - Initialization
//    
//    public convenience init(method: HTTPVerb, fullUrl: URL, completed: (result: WebResult<T, U>) -> Void) {
//        self.init(method: method, fullUrl: fullUrl)
//        completedCallback = completed
//    }
//    
//    public init(method: HTTPVerb, fullUrl: URL) {
//        self.method = method
//        self.url = fullUrl
//    }
//    
//    // MARK: - Properties
//    
//    public let method: HTTPVerb
//    public let url: URL
//    
//    public var additionalHeaders: [String: String]?
//    public var requestObject: SerializableObject?
//    
//    public var completedCallback: ((result: WebResult<T, U>) -> Void)?
//    
//    public var displayNetworkActivity = false
//    
//    // MARK: - Methods
//    
//    public func setCompletedCallback(_ callback: ((result: WebResult<T, U>) -> Void)?) {
//        completedCallback = callback
//    }
//}

public struct WebRequestID: Equatable {
    init(_ id: String) { identifier = id }
    let identifier: String
}
public func ==(lhs: WebRequestID, rhs: WebRequestID) -> Bool {
    return lhs.identifier == rhs.identifier
}


open class WebRequest {
    
//    public typealias WebRequestCallback = (WebResult<T, U>) -> Void
    
    // MARK: - Initialization
    
//    public convenience init(method: HTTPVerb, fullUrl: URL, completed: WebRequestCallback) {
//        self.init(method: method, fullUrl: fullUrl)
//        completedCallback = completed
//    }
    
    public init(method: HTTPVerb, fullUrl: URL) {
        self.method = method
        self.url = fullUrl
    }
    
    // MARK: - Properties
    
    // The unique id of this request
    public lazy var requestID = WebRequestID(UUID.init().uuidString)
    
    // Request verb
    public let method: HTTPVerb
    // Full url
    public let url: URL
    
    // Additional headers to add to default
    public var additionalHeaders: [String: String]?
    // The object to serialize as body
    public var requestObject: SerializableObject?
    // Whether this request should activate the network activity indicator
    public var displayNetworkActivity = false
    
//    // The request's callback
//    public var completedCallback: WebRequestCallback?
//    
//    // MARK: - Methods
//    
//    public func setCompletedCallback(_ callback: ((_ result: WebResult<T, U>) -> Void)?) {
//        completedCallback = callback
//    }
}



/**
open class WebRequest<T: DeserializableObject, U: DeserializableObject> {
    
    public typealias WebRequestCallback = (WebResult<T, U>) -> Void
    
    // MARK: - Initialization
    
    public convenience init(method: HTTPVerb, fullUrl: URL, completed: WebRequestCallback) {
        self.init(method: method, fullUrl: fullUrl)
        completedCallback = completed
    }
    
    public init(method: HTTPVerb, fullUrl: URL) {
        self.method = method
        self.url = fullUrl
    }
    
    // MARK: - Properties
    
    // The unique id of this request
    public lazy var requestID = WebRequestID(UUID.init().uuidString)
    
    // Request verb
    public let method: HTTPVerb
    // Full url
    public let url: URL
    
    // Additional headers to add to default
    public var additionalHeaders: [String: String]?
    // The object to serialize as body
    public var requestObject: SerializableObject?
    // Whether this request should activate the network activity indicator
    public var displayNetworkActivity = false
    
    // The request's callback
    public var completedCallback: WebRequestCallback?
    
    // MARK: - Methods
    
    public func setCompletedCallback(_ callback: ((_ result: WebResult<T, U>) -> Void)?) {
        completedCallback = callback
    }
}
**/
 
