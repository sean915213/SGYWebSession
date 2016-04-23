//
//  UITableViewExtension.swift
//  Pods
//
//  Created by Sean G Young on 2/13/16.
//
//

import Foundation

extension UITableView {
    
     /**
     Attempts dequeueing a registered `UITableViewCell` and casting to `T` before returning.
     
     - parameter identifier: The cell's registered `reuseIdentifier`.
     
     - returns: A dequeued `UITableViewCell` cast to `T`.  Returns `nil` if no cell is returned by the table.
     */
    public func dequeueReusableCellWithIdentifier<T: UITableViewCell>(identifier: String) -> T? {
        // This version can return nil so make sure it returns a cell before force-casting
        guard let cell = dequeueReusableCellWithIdentifier(identifier) else { return nil }
        // Force cast
        return (cell as! T)
    }
    
    /**
     Dequeues a registered `UITableViewCell` and casting to type `T` before returning.
     
     - parameter identifier: The cell's registered `reuseIdentifier`.
     - parameter indexPath:  The index path to dequeue the cell for.
     
     - returns: A dequeued `UITableViewCell` instance cast to `T`.  This method will always return a cell.
     */
    public func dequeueReusableCellWithIdentifier<T: UITableViewCell>(identifier: String, forIndexPath indexPath: NSIndexPath) -> T {
        return self.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! T
    }
    
    /**
     Attempts dequeueing a registered `UITableViewHeaderFooterView` and casting to type `T` before returning.
     
     - parameter identifier: The view's registered `reuseIdentifier`.
     
     - returns: A dequeued `UITableViewHeaderFooterView` cast to `T`.  Returns `nil` if no reusable view was found in the queue.
     */
    public func dequeueReusableHeaderFooterViewWithIdentifier<T: UITableViewHeaderFooterView>(identifier: String) -> T? {
        // Check view can be returned before force casting
        guard let view = dequeueReusableHeaderFooterViewWithIdentifier(identifier) else { return nil }
        // Force cast
        return (view as! T)
    }
}
