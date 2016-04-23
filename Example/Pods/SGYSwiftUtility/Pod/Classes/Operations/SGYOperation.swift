//
//  SGYOperation.swift
//  Pods
//
//  Created by Sean G Young on 4/23/16.
//
//

import UIKit

public class SGYOperation: NSOperation {
    
    // MARK: - Initialization
    
    public override init() {
        self.logger = Logger(contextDescription: NSStringFromClass(self.dynamicType))
        super.init()
    }
    
    // MARK: - Properties
    
    public var logger: Logger
}
