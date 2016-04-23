//
//  HTTPEnumerations.swift
//  Pods
//
//  Created by Sean G Young on 4/23/16.
//
//

import Foundation

public enum HTTPVerb : String, CustomStringConvertible {
    case DELETE = "DELETE", GET = "GET", POST = "POST", PUT = "PUT"
    
    public var description: String { return rawValue }
}

public enum HTTPHeader : String, CustomStringConvertible {
    case Authorization = "Authorization",
    AcceptContentType = "Accept",
    RequestContentType = "Content-Type"
    
    public var description: String { return rawValue }
}

// Enum with mimetypes
public enum MimeType: String, CustomStringConvertible {
    case HTML = "text/html",
    JSON = "application/json",
    PDF = "application/pdf"
    
    public var description: String { return rawValue }
}


// Enum with relevant NSError result codes
public enum URLTaskNSErrorCode: Int {
    case Cancelled = -999,
    ConnectionTimedOut = -1001,
    CannotConnectToHost = -1004,
    LostConnection = -1005,
    ConnectionUnavailable = -1009
}

// Codes obtained from W3C spec: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
// Enum with defined http 1.1 status codes.
public enum HTTPStatusCode: Int, CustomStringConvertible {
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
    
    public var description: String { return "\(rawValue)" }
}
