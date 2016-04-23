//
//  BWSProtocols.swift
//  TheGalaxy
//
//  Created by Sean Young on 11/10/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import Foundation

public protocol BWSJSONDeserializableObject {
    static func fromJSONData(data: NSData) throws -> Self
}

public protocol BWSJSONSerializableObject {
    func JSONData() throws -> NSData
}