//
//  BWSTaskRequest2.swift
//  TheGalaxy
//
//  Created by Sean Young on 11/13/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import Foundation

class BWSTaskRequest<T: BWSJSONDeserializableObject, U: BWSJSONDeserializableObject> {
    
    // MARK: - Initialization
    
    convenience init(method: HTTPVerb, fullUrl: NSURL, completed: (result: BWSRequestResult<T, U>) -> Void) {
        self.init(method: method, fullUrl: fullUrl)
        completedCallback = completed
    }
    
    init(method: HTTPVerb, fullUrl: NSURL) {
        self.method = method
        self.url = fullUrl
    }
    
    // MARK: - Properties
    
    let method: HTTPVerb
    let url: NSURL
    
    var additionalHeaders: [String: String]?
    var requestObject: BWSJSONSerializableObject?
    
    var completedCallback: ((result: BWSRequestResult<T, U>) -> Void)?
    
    // MARK: - Methods
    
    func setCompletedCallback(callback: ((result: BWSRequestResult<T, U>) -> Void)?) { completedCallback = callback }
    
}