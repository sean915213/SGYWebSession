//
//  WebResult.swift
//
//  Created by Sean Young on 10/7/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import Foundation

public enum WebResultStatus {
    // Basic results
    case ok,
    connectionUnavailable,
    timedOut,
    connectionLost,
    notAuthorized,
    clientError(HTTPStatusCode),
    serverError(HTTPStatusCode),
    serializationFailed(Error),
    deserializationFailed(Error),
    cancelled,
    otherError(Error),
    unknownError
}

public protocol WebResultProtocol: class {
    associatedtype ExpectedPayload: DeserializableObject
    associatedtype ErrorPayload: DeserializableObject
    
    init(status: WebResultStatus, response: HTTPURLResponse?)
    
    var status: WebResultStatus { get }
    var response: HTTPURLResponse? { get }
    
    var error: Error? { get }
    
    var responseData: Data? { get set }
    var typedPayload: ExpectedPayload? { get set }
    var typedError: ErrorPayload? { get set }
    
    var responseCode: HTTPStatusCode? { get }
    var mimeType: MimeType? { get }
}

open class WebResult<T: DeserializableObject, U: DeserializableObject>: WebResultProtocol {
    
    // MARK: - Initialization
    
    public convenience init(status: WebResultStatus) {
        self.init(status: status, response: nil)
    }
    
    public required init(status: WebResultStatus, response: HTTPURLResponse?) {
        self.status = status
        self.response = response
    }
    
    // MARK: - Properties
    
    public let status: WebResultStatus
    public let response: HTTPURLResponse?
    
    public var error: Error? {
        switch self.status {
        case .serializationFailed(let err), .deserializationFailed(let err): return err
        case .otherError(let err): return err
        default: return nil
        }
    }

    public var responseData: Data?
    public var typedPayload: T?
    public var typedError: U?
    
    public var responseCode: HTTPStatusCode? {
        guard let code = response?.statusCode else { return nil }
        return HTTPStatusCode(rawValue: code)
    }
    
    public var mimeType: MimeType? {
        guard let mimeType = response?.mimeType else { return nil }
        return MimeType(rawValue: mimeType)
    }
}
















