//
//  SecondsValueTransformer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 16/08/2020.
//  Copyright © 2020 Pierre Couprie. All rights reserved.
//

import Foundation

@objc(SecondsValueTransformer) class SecondsValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let seconds = value as? Double {
            return NSString(format: "%.01f sec.", seconds) as String
        }
        return "0.0 sec."
    }
    
}
