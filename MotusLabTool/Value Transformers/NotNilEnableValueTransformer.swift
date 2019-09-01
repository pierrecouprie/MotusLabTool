//
//  NotNilEnableValueTransformer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 31/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation

@objc(NotNilEnableValueTransformer) class NotNilEnableValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if value != nil {
            return true
        }
        
        return false
    }
    
}
