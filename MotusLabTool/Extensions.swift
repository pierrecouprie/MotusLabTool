//
//  Extensions.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 28/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

extension CALayer {
    
    /// Add contraints in a CALayer to fit to its superlayer
    ///
    /// - Parameter superlayer: The superlayer
    func addInLayerContraints(superlayer: CALayer) {
        superlayer.name = "superlayer"
        let leftConstraint = CAConstraint(attribute: .minX,
                                          relativeTo: "superlayer",
                                          attribute: .minX)
        let rightConstraint = CAConstraint(attribute: .maxX,
                                           relativeTo: "superlayer",
                                           attribute: .maxX)
        let topConstraint = CAConstraint(attribute: .minY,
                                         relativeTo: "superlayer",
                                         attribute: .minY)
        let bottomConstraint = CAConstraint(attribute: .maxY,
                                            relativeTo: "superlayer",
                                            attribute: .maxY)
        self.constraints = [leftConstraint, rightConstraint, topConstraint, bottomConstraint]
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
    
    /// Convert Float value to time formated value (minutes and seconds
    ///
    /// - Parameter value : The time in milliseconds
    /// - Returns : The time in format 00:00
    func floatToTimeSeconds() -> String {
        guard !self.isNaN && !self.isInfinite && self >= 0 else {
            return "00:00"
        }
        let seconds:Int = Int(floor(self).truncatingRemainder(dividingBy: 60))
        let minutes:Int = Int(floor(self)/60)
        
        let counterString:String = NSString(format: "%02d:%02d", minutes,seconds) as String
        
        return counterString
    }
    
    /// Convert linear values (0 to 1) to decibel values (-160 to 0)
    var decibel: Float {
        var result = 20.0 * log10(abs(self))
        if result < -160 || result == Float.infinity {
            result = -160
        }
        return result
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
    
    /// Convert String value to time Float value
    /// Self: The time in String formated as 00:00.00
    ///
    /// - Returns: The time in Float value (milliseconds)
    func stringToTime() -> Float {
        
        var value: Float = 0.0
        var minutes: Float = 0
        var seconds: Float = 0
        var thousandth: Float = 0
        
        let minutesArray = self.components(separatedBy: ":")
        
        if let min = Float(minutesArray[0]) {
            minutes = min
        }
        
        if minutesArray.count > 1 {
            let secondsArray = minutesArray[1].components(separatedBy: ".")
            
            if let sec = Float(secondsArray[0]) {
                seconds = sec
            }
            
            if secondsArray.count > 1 {
                if let thou = Float(secondsArray[1]) {
                    thousandth = thou
                }
            }
        } else {
            seconds = minutes
            minutes = 0
        }
        
        value += Float(minutes*60)
        value += Float(seconds)
        value += Float(thousandth/1000)
        
        return value
        
    }
    
    
}

extension URL {
    
    /// Extract file name from an URL
    var fileName: String {
        return self.deletingPathExtension().lastPathComponent
    }
    
}

extension Notification.Name {
    static let midiDidChange = Notification.Name("midiDidChange")
}
