//
//  UICollectionViewExtension.swift
//  Pods
//
//  Created by Sean G Young on 2/13/16.
//
//

import Foundation

extension UICollectionView {
    
    /**
     Provides a method for dequeueing typed cells from `UICollectionView`.
     
     - parameter identifier: The `UICollectionViewCell`'s registered `reuseIdentifier`.
     - parameter indexPath:  The `NSIndexPath` to dequeue the cell for.
     
     - returns: A dequeued `UICollectionViewCell` cast to type `T`.
     */
    public func dequeueReusableCellWithReuseIdentifier<T: UICollectionViewCell>(_ identifier: String, forIndexPath indexPath: IndexPath) -> T {
        return dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! T
    }
    
    /**
     Provides a method for dequeueing typed supplementary views from `UICollectionView`.
     
     - parameter elementKind:     The kind of supplementary view.
     - parameter reuseIdentifier: The `UICollectionReusableView`'s registered `reuseIdentifier`.
     - parameter indexPath:       The `NSIndexPath` to dequeue the view for.
     
     - returns: A dequeued `UICollectionReusableView` cast to type `T`.
     */
    public func dequeueReusableSupplementaryViewOfKind<T: UICollectionReusableView>(_ elementKind: String, withReuseIdentifier reuseIdentifier: String, forIndexPath indexPath: IndexPath) -> T {
        return dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: reuseIdentifier, for: indexPath) as! T
    }
}
