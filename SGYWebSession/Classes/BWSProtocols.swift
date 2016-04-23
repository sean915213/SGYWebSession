//
//  BWSProtocols.swift
//  TheGalaxy
//
//  Created by Sean Young on 11/10/15.
//  Copyright © 2015 Sean G Young. All rights reserved.
//

import Foundation

protocol BWSJSONDeserializableObject {
    static func fromJSONData(data: NSData) throws -> Self
}

protocol BWSJSONSerializableObject {
    func JSONData() throws -> NSData
}