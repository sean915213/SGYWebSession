//
//  HTTPEnumerations.swift
//
//  Created by Sean G Young on 4/23/16.
//

import Foundation
import MobileCoreServices

public enum HTTPVerb : String, CustomStringConvertible {
    case delete = "DELETE", get = "GET", post = "POST", put = "PUT"
    
    public var description: String { return rawValue }
}

public enum HTTPHeader : String, CustomStringConvertible {
    case authorization = "Authorization",
    acceptContentType = "Accept",
    requestContentType = "Content-Type"
    
    public var description: String { return rawValue }
}

// Enum with mimetypes
public enum MimeType: String, CustomStringConvertible {
    case html = "text/html",
    json = "application/json",
    pdf = "application/pdf"
    
    public var description: String { return rawValue }
    
    public var uti: String? {
        guard let utiType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, rawValue as CFString, nil) else { return nil }
        return utiType.takeUnretainedValue() as String
    }
}


// Enum with relevant NSError result codes
public enum URLTaskNSErrorCode: Int {
    case cancelled = -999,
    connectionTimedOut = -1001,
    cannotConnectToHost = -1004,
    lostConnection = -1005,
    connectionUnavailable = -1009
}

// Codes obtained from W3C spec: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
// Enum with defined http 1.1 status codes.
public enum HTTPStatusCode: Int, CustomStringConvertible {
    // Informational
    case `continue` = 100,
    switchingProtocols = 101,
    // Success
    success = 200,
    created = 201,
    accepted = 202,
    nonAuthoritativeInformation = 203,
    noContent = 204,
    resetContent = 205,
    partialContent = 206,
    // Redirection
    multipleChoices = 300,
    movedPermanently = 301,
    found = 302,
    seeOther = 303,
    notModified = 304,
    useProxy = 305,
    __unused = 306, // Not used in HTTP 1.1 spec
    temporaryRedirect = 307,
    // Client Error
    badRequest = 400,
    unauthorized = 401,
    __paymentRequired = 402, // Reserved for future use per HTTP 1.1 spec
    forbidden = 403,
    notFound = 404,
    methodNotAllowed = 405,
    notAcceptable = 406,
    proxyAuthenticationRequired = 407,
    requestTimedOut = 408,
    conflict = 409,
    gone = 410,
    lengthRequired = 411,
    preconditionFailed = 412,
    requestEntityTooLarge = 413,
    requestURITooLong = 414,
    unsupportedMediaType = 415,
    requestedRangeNotSatisfiable = 416,
    expectationFailed = 417,
    // Server Error
    internalServerError = 500,
    notImplemented = 501,
    badGateway = 502,
    serviceUnavailable = 503,
    gatewayTimeout = 504,
    httpVersionNotSupported = 505
    
    public var description: String { return "\(rawValue)" }
}
