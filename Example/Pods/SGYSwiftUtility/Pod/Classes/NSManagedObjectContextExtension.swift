//
//  NSManagedObjectContextExtension.swift
//  SGYSwiftUtility
//
//  Created by Sean G Young on 2/13/16.
//
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    /**
     Attempts fetching an existing `NSManagedObject` by the `objectID` and casting to `T` before returning.
     
     - parameter objectID: The `NSManagedObject`'s `objectID`.
     
     - throws: Throws any error thrown by `existingObjectWithID:`.
     
     - returns: The `NSManagedObject` fetched by `objectID` cast to `T`.
     */
    public func existingObjectWithID<T: NSManagedObject>(objectID: NSManagedObjectID) throws -> T {
        // Force cast since object not found will throw and if an object is found of the wrong type the caller messed up.
        return try existingObjectWithID(objectID) as! T
    }
    
    /**
     Executes `request` and returns an array of `Element` cast to type `T`.
     
     - parameter request: The `NSFetchRequest` describing the fetch.
     
     - throws: Throws any error thrown by `executeFetchRequest:`.
     
     - returns: An array of `Element` cast to type `T`. This method always returns an array, though it may be empty if `request` does not match any objects.
     */
    public func executeMultiFetchRequest<T: NSManagedObject>(request: NSFetchRequest) throws -> [T] {
        // Force cast since a nil-array is never expected (error is throw instead) and it is caller's responsibility to be sure of the type.
        return try executeFetchRequest(request) as! [T]
    }
    
    /**
     Executes `request` and returns a single object of type `T` or `nil`.
     
     - parameter request: The `NSFetchRequest` describing the fetch.
     
     - throws: Throws any error thrown by `executeFetchRequest:`.
     
     - returns: The first object cast to type `T` that is returned by the fetch request or `nil` if no results are returned.
     */
    public func executeSingleFetchRequest<T: NSManagedObject>(request: NSFetchRequest) throws -> T? {
        // We only expect one entry so limit request
        request.fetchLimit = 1
        return try executeFetchRequest(request).first as? T
    }
}