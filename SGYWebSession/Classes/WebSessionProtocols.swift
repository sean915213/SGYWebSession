//
//  WebSessionProtocols.swift
//
//  Created by Sean Young on 11/10/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import Foundation

public protocol DeserializableObject {
    static func fromJSONData(_ data: Data) throws -> Self
}

public protocol SerializableObject {
    func JSONData() throws -> Data
}
