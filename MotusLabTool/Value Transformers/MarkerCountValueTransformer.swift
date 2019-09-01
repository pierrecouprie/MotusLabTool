//
//  MarkerCountValueTransformer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation

@objc(MarkerCountValueTransformer) class MarkerCountValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let count = value as? Int {
            if count == 1 {
                return String(count) + " marker"
            } else if count > 1 {
                return String(count) + " markers"
            }
        }
        
        return "0 marker"
    }
    
}
