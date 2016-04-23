//
//  StringExtension.swift
//  Pods
//
//  Created by Sean G Young on 2/13/16.
//
//

import Foundation

extension String {
    /// The `String`'s length using utf-8 encoding.
    public var lengthWithUTF8Encoding: Int { return lengthOfBytesUsingEncoding(NSUTF8StringEncoding) }
    
}