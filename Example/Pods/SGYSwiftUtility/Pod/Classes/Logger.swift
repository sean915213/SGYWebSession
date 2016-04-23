//
//  Logger.swift
//
//  Created by Sean G Young on 2/8/15.
//  Copyright (c) 2015 Sean G Young. All rights reserved.
//

import Foundation

/**
 The log levels supported by Logger.
 
 - Debug: A debugging logging.  Generally considered temporary.
 - Info: An informational log.  Denotes a log that is useful to see and indicates no problems.
 - Warning: A warning log.  Denotes an issue that can be recovered from, but should be noted as it is likely not functioning properly.
 - Error: An error log.  Denotes a crtitical error that may or may not be recovered from and should be addressed immediately.
 */
public enum LogLevel: String, CustomStringConvertible {
    case Debug = "Debug",
    Info = "Info",
    Warning = "Warning",
    Error = "Error"
    
    public var description: String { return rawValue }
}

public enum LogFormatPlaceholder: String, CustomStringConvertible {
    case ContextDescription = "$context",
    Level = "$logLevel",
    Value = "$logValue"
    
    public var description: String { return rawValue }
}

public typealias LoggingBlock = (String) -> Void

// Defaults
private let defaultLogFormat = "[\(LogFormatPlaceholder.ContextDescription)] \(LogFormatPlaceholder.Level) - \(LogFormatPlaceholder.Value)"
private let defaultLogBlock: LoggingBlock = { NSLog($0) }

/**
 *  Provides a logging interface with a predefined structure.
 */
public class Logger {
    
    // MARK: - Initialization
    
    /**
     Initializes a SerialLogger instance.
     
     :param: contextDescription The description that all logs printed using this instance will be prefixed with.
     
     :returns: An instance of the SerialLogger class.
     */
    public convenience init(contextDescription: String) {
        // Use default log format
        self.init(contextDescription: contextDescription, logFormat: defaultLogFormat, logBlock: defaultLogBlock)
    }
    
    public convenience init(contextDescription: String, logBlock: LoggingBlock) {
        // Use default log format
        self.init(contextDescription: contextDescription, logFormat: defaultLogFormat, logBlock: logBlock)
    }
    
    public init(contextDescription: String, logFormat: String, logBlock: LoggingBlock) {
        self.logFormat = logFormat
        self.contextDescription = contextDescription
        self.logBlock = logBlock
    }
    
    // MARK: - Properties
    
    /// The description prefixed to logs.  Assigned on initialization.
    public var contextDescription: String
    /// The format used to create the final logging string.
    public let logFormat: String
    /// The block used to perform actual logging action.
    private let logBlock: LoggingBlock
    
    // MARK: - Methods
    
    /**
     Executes a log statement.
     
     :param: description The text to log.
     :param: level       The log level to display.
     */
    public func log(description: String, level: LogLevel = .Debug) {
        
        // Create log description by replacing placeholders w/ their respective values
        var log = logFormat.stringByReplacingOccurrencesOfString(LogFormatPlaceholder.ContextDescription.rawValue, withString: contextDescription)
        log = log.stringByReplacingOccurrencesOfString(LogFormatPlaceholder.Level.rawValue, withString: level.rawValue)
        log = log.stringByReplacingOccurrencesOfString(LogFormatPlaceholder.Value.rawValue, withString: description)
        
        // Log it
        logBlock(log)
    }
}

// MARK: Convenience Methods Extension

extension Logger {
    
    public func logDebug(value: String) {
        log(value, level: .Debug)
    }
    
    public func logInfo(value: String) {
        log(value, level: .Info)
    }
    
    public func logWarning(value: String) {
        log(value, level: .Warning)
    }
    
    public func logError(value: String) {
        log(value, level: .Error)
    }
}

// MARK: CustomStringConvertible Extension

extension Logger {
    
    public func logDebug(@autoclosure value: () -> CustomStringConvertible) {
        log(.Debug, value: value)
    }
    
    public func logInfo(@autoclosure value: () -> CustomStringConvertible) {
        log(.Info, value: value)
    }
    
    public func logWarning(@autoclosure value: () -> CustomStringConvertible) {
        log(.Warning, value: value)
    }
    
    public func logError(@autoclosure value: () -> CustomStringConvertible) {
        log(.Error, value: value)
    }
    
    private func log(level: LogLevel, @autoclosure value: () -> CustomStringConvertible) {
        // Value block execution could be non-trivial, so don't even bother if not debugging
        #if DEBUG
            log(value().description, level: level)
        #endif
    }
}