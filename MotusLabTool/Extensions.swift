//
//  Extensions.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 28/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

extension NSView {
    
    /// Add contraints in a subview to fit to its superview
    ///
    /// - Parameter superView: The superview
    func addInViewConstraints(superView: NSView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: superView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: superView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant:0.0).isActive = true
        NSLayoutConstraint(item: superView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: superView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
    }
    
}

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

extension NSColor {
    
    /// Convert color to Data (used for preferences)
    ///
    /// - returns: Data
    var data: Data {
        get {
            return NSKeyedArchiver.archivedData(withRootObject: self)
        }
    }
    
}

extension Data {
    
    /// Convert data to color (used for preferences)
    ///
    /// returns: NSColor
    var color: NSColor {
        get {
            if let data = NSKeyedUnarchiver.unarchiveObject(with: self), let dataColor = data as? NSColor {
                return dataColor
            }
            return NSColor.gray
        }
    }
    
}

extension String {
    
    /// Return version of software
    static var motusLabToolVersion: String {
        if let dictionary = Bundle.main.infoDictionary, let version = dictionary["CFBundleShortVersionString"] as? String {
            return version
        }
        
        return ""
    }
}

extension URL {
    
    /// Extract file name from an URL
    var fileName: String {
        return self.deletingPathExtension().lastPathComponent
    }
    
}
