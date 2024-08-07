//
//  SharedExtensions.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 06/08/2024.
//  Copyright © 2024 Pierre Couprie. All rights reserved.
//

import Foundation

extension Float {
    
    /// Convert Float value to time formated value
    ///
    /// - Parameter value : The time in milliseconds
    /// - Returns : The time in format 00:00.00
    func floatToTime() -> String {
        guard !self.isNaN && !self.isInfinite && self >= 0 else {
            return "00:00.000"
        }
        let seconds:Int = Int(floor(self).truncatingRemainder(dividingBy: 60))
        let minutes:Int = Int(floor(self)/60)
        let tenth:Int = Int((self - floor(self)) * 1000)
        
        let counterString:String = NSString(format: "%02d:%02d.%03d", minutes,seconds,tenth) as String
        
        return counterString
    }
    
}

enum NSKeyedUnarchiverError: Error {
    case errorReadingData
}

extension NSKeyedUnarchiver {
    
    static func unarchive<T: NSObject & NSCoding>(data: Data, of type: T.Type) throws -> T? {
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false
            let openedFile = unarchiver.decodeObject(of: T.self, forKey: NSKeyedArchiveRootObjectKey)
            unarchiver.finishDecoding()
            return openedFile
        } catch {
            throw NSKeyedUnarchiverError.errorReadingData
        }
        
    }
    
}
