//
//  BWSRequestResult2.swift
//  TheGalaxy
//
//  Created by Sean Young on 10/7/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import Foundation

enum BWSResultStatus: String, CustomStringConvertible {
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
    
    var description: String { return "\(rawValue)" }
}


// Enum with relevant NSError result codes
enum URLTaskNSErrorCode: Int {
    case Cancelled = -999,
    ConnectionTimedOut = -1001,
    CannotConnectToHost = -1004,
    LostConnection = -1005,
    ConnectionUnavailable = -1009
}

// Codes obtained from W3C spec: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
// Enum with defined http 1.1 status codes.
enum HTTPStatusCode: Int, CustomStringConvertible {
    // Informational
    case Continue = 100,
    SwitchingProtocols = 101,
    // Success
    Success = 200,
    Created = 201,
    Accepted = 202,
    NonAuthoritativeInformation = 203,
    NoContent = 204,
    ResetContent = 205,
    PartialContent = 206,
    // Redirection
    MultipleChoices = 300,
    MovedPermanently = 301,
    Found = 302,
    SeeOther = 303,
    NotModified = 304,
    UseProxy = 305,
    __Unused = 306, // Not used in HTTP 1.1 spec
    TemporaryRedirect = 307,
    // Client Error
    BadRequest = 400,
    Unauthorized = 401,
    __PaymentRequired = 402, // Reserved for future use per HTTP 1.1 spec
    Forbidden = 403,
    NotFound = 404,
    MethodNotAllowed = 405,
    NotAcceptable = 406,
    ProxyAuthenticationRequired = 407,
    RequestTimedOut = 408,
    Conflict = 409,
    Gone = 410,
    LengthRequired = 411,
    PreconditionFailed = 412,
    RequestEntityTooLarge = 413,
    RequestURITooLong = 414,
    UnsupportedMediaType = 415,
    RequestedRangeNotSatisfiable = 416,
    ExpectationFailed = 417,
    // Server Error
    InternalServerError = 500,
    NotImplemented = 501,
    BadGateway = 502,
    ServiceUnavailable = 503,
    GatewayTimeout = 504,
    HTTPVersionNotSupported = 505
    
    var description: String { return "\(rawValue)" }
}


class BWSRequestResult<T, U> {
    
    // MARK: - Initialization
    
    convenience init(error: NSError) {
        self.init(response: nil, error: error, status: nil)
    }
    
    convenience init(status: BWSResultStatus) {
        self.init(response: nil, error: nil, status: status)
    }
    
    convenience init(response: NSURLResponse) {
        self.init(response: response, error: nil, status: nil)
    }
    
    required init(response: NSURLResponse?, error: NSError?, status: BWSResultStatus?) {
        self.response = response
        self.error = error
        self.storedStatus = status
    }
    
    // MARK: - Properties
    
    let response: NSURLResponse?
    let error: NSError?
    private let storedStatus: BWSResultStatus?
    
    var typedPayload: T?
    var typedError: U?
    
    var HTTPResponse: NSHTTPURLResponse? { return response as? NSHTTPURLResponse }
    
    lazy var responseCode: HTTPStatusCode? = {
        return HTTPStatusCode(rawValue: self.HTTPResponse?.statusCode ?? -1)
    }()
    
    lazy var responseMimeType: MimeType? = {
        return MimeType(rawValue: self.HTTPResponse?.MIMEType ?? "")
    }()
    
    lazy var status: BWSResultStatus = {
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
















