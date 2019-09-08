//
//  NSButtonStateIntegerValueTransformer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 08/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

/// Used in Playlist toolbar button
@objc(NSButtonStateIntegerValueTransformer) class NSButtonStateIntegerValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let state = value as? NSButton.StateValue {
            if state == .on {
                return 1
            }
        }
        
        return 0
    }
    
}
