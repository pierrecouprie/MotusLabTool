//
//  SimpleTimeValueTransformer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 08/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation

/// Convert Float time value (eg 0) to String time value (eg "00:00.000")
@objc(SimpleTimeValueTransformer) class SimpleTimeValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let time = value as? Float {
            return time.floatToTimeSeconds()
        }
        
        return "00:00"
    }
    
}
