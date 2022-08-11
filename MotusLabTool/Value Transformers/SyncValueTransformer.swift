//
//  SyncValueTransformer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 25/08/2021.
//  Copyright © 2021 Pierre Couprie. All rights reserved.
//

import Foundation

@objc(SyncValueTransformer) class SyncValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let sync = value as? Int {
            return sync == 2 ? false : true
        }
        return true
    }
    
}
