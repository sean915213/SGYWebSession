//
//  BWSRequestResult2.swift
//  TheGalaxy
//
//  Created by Sean Young on 10/7/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import Foundation
import MobileCoreServices

public enum BWSResultStatus: String, CustomStringConvertible {
    case OK = "OK",
    ConnectionUnavailable = "ConnectionUnavailable",
    TimedOut = "TimedOut",
    ConnectionLost = "ConnectionLost",
    NotAuthorized = "NotAuthorized",
    ClientError = "ClientError",
    ServerError = "ServerError",
    RequestSerializationFailed = "RequestSerializationFailed",
    ResponseDeserializationFailed = "ResponseDeserializationFailed",
    Cancelled = "Cancelled",
    OtherError = "OtherError"
    
    public var description: String { return rawValue }
}

public class BWSRequestResult<T, U> {
    
    // MARK: - Initialization
    
    public convenience init(error: NSError) {
        self.init(response: nil, error: error, status: nil)
    }
    
    public convenience init(status: BWSResultStatus) {
        self.init(response: nil, error: nil, status: status)
    }
    
    public convenience init(response: NSURLResponse) {
        self.init(response: response, error: nil, status: nil)
    }
    
    public required init(response: NSURLResponse?, error: NSError?, status: BWSResultStatus?) {
        self.response = response
        self.error = error
        self.storedStatus = status
    }
    
    // MARK: - Properties
    
    public let response: NSURLResponse?
    public let error: NSError?
    
    private let storedStatus: BWSResultStatus?
    
    public var typedPayload: T?
    public var typedError: U?
    
    public var HTTPResponse: NSHTTPURLResponse? { return response as? NSHTTPURLResponse }
    
    public lazy var responseCode: HTTPStatusCode? = {
        guard let code = self.HTTPResponse?.statusCode else { return nil }
        return HTTPStatusCode(rawValue: code)
    }()
    
    public lazy var responseMimeType: MimeType? = {
        guard let mimeType = self.HTTPResponse?.MIMEType else { return nil }
        return MimeType(rawValue: mimeType)
    }()
    
    public lazy var responseUTI: String? = {
        guard let mimeType = self.HTTPResponse?.MIMEType, utiType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, nil) else { return nil }
        return utiType.takeUnretainedValue() as String
    }()
    
    public lazy var status: BWSResultStatus = {
        // If stored status exists assign that
        if let storedStatus = self.storedStatus { return storedStatus }
        
        // First check whether we got a response code back (takes higher priority in determining status than errors)
        if let httpStatusCode = self.responseCode {
            let code = httpStatusCode.rawValue
            // Check for the "Client Error" domain of codes
            if code >= 400 && code < 500 {
                switch httpStatusCode {
                // Check explicitly for 401 Unauthorized
                case .Unauthorized: return .NotAuthorized
                // Otherwise return generic client error code
                default: return .ClientError
                }
            }
            // Check for "Server Error" domain (less than portion is just to adhere to specification since this is technically the last domain and > 600 is not expected)
            else if code >= 500 && code < 600 {
                return .ServerError
            }
        }
        
        // Use an error if it exists to determine status
        if let errorCode = self.error?.code {
            // Check for an NSURL relevant error
            guard let relevantError = URLTaskNSErrorCode(rawValue: errorCode) else { return .OtherError }
            // Switch on error
            switch relevantError {
            case .Cancelled: return .Cancelled
            case .ConnectionTimedOut: return .TimedOut
            case .CannotConnectToHost: return .TimedOut
            case .ConnectionUnavailable: return .ConnectionUnavailable
            case .LostConnection: return .ConnectionLost
            }
        }
        
        // Otherwise return an OK status
        return .OK
    }()
}
















