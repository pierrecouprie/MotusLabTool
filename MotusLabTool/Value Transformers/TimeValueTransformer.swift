//
//  TimeValueTransformer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation

@objc(TimeValueTransformer) class TimeValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let time = value as? Float {
            return time.floatToTime()
        }
        
        return "00:00.000"
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let timeStr = value as? String {
            let timeFl = timeStr.stringToTime()
            return timeFl
        }
        return Float(0)
    }
    
}
