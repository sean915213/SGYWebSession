//
//  NSDateExtension.swift
//  Pods
//
//  Created by Sean G Young on 2/13/16.
//
//

import Foundation

extension NSDate {
    
     /**
     Constructs an `NSDate` instance from a unix timestamp (ie. number of milliseconds since January 1, 1970).
     
     - parameter unixTimeStamp: A `Double` representing the unix timestamp.
     
     - returns: An initialized `NSDate` instance.
     */
    public convenience init(unixTimeStamp: Double) {
        self.init(timeIntervalSince1970: unixTimeStamp / 1000.0)
    }
    
    /// Returns the `NSDate` instance's unix timestamp (ie. number of milliseconds since January 1, 1970).
    public var unixTimeStamp: Double {
        return timeIntervalSince1970 * 1000
    }
}