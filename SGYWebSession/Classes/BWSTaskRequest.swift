//
//  BWSTaskRequest.swift
//
//  Created by Sean Young on 11/13/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import Foundation

public class BWSTaskRequest<T: BWSJSONDeserializableObject, U: BWSJSONDeserializableObject> {
    
    // MARK: - Initialization
    
    public convenience init(method: HTTPVerb, fullUrl: NSURL, completed: (result: BWSRequestResult<T, U>) -> Void) {
        self.init(method: method, fullUrl: fullUrl)
        completedCallback = completed
    }
    
    public init(method: HTTPVerb, fullUrl: NSURL) {
        self.method = method
        self.url = fullUrl
    }
    
    // MARK: - Properties
    
    public let method: HTTPVerb
    public let url: NSURL
    
    public var additionalHeaders: [String: String]?
    public var requestObject: BWSJSONSerializableObject?
    
    public var completedCallback: ((result: BWSRequestResult<T, U>) -> Void)?
    
    // MARK: - Methods
    
    public func setCompletedCallback(callback: ((result: BWSRequestResult<T, U>) -> Void)?) {
        completedCallback = callback
    }
}