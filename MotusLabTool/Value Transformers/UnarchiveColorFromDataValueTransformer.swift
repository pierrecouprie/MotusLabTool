//
//  UnarchiveFromDataValueTransformer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 06/08/2024.
//  Copyright © 2024 Pierre Couprie. All rights reserved.
//

import Foundation
import AppKit

@objc(UnarchiveColorFromDataValueTransformer) class UnarchiveColorFromDataValueTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let value = value as? Data {
            return try? NSKeyedUnarchiver.unarchive(data: value,
                                                    of: NSColor.self)
        }
        
        return nil
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let value = value as? NSColor {
            return try? NSKeyedArchiver.archivedData(withRootObject: value,
                                                     requiringSecureCoding: false)
        }
        return nil
    }
    
}
