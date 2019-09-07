//
//  NSButtonCellCounter.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
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

class NSButtonCellCounter: NSButtonCell {

    var counterValue: Float = 0
    
    
    /// Formating the string to draw from :
    /// - counterValue
    /// - filename
    func createCounterText() -> String {
        let counterStr: String = self.counterValue.floatToTime()
        return counterStr
    }
    
    /// Drawing the string label
    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
        
        let counterStr: NSString = self.createCounterText() as NSString
        let font = NSFont.systemFont(ofSize: 12)
        
        let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        textStyle.alignment = NSTextAlignment.left
        textStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
        let textColor = NSColor.labelColor
        
        let textFontAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.paragraphStyle: textStyle,
        ]
        
        counterStr.draw(in: NSOffsetRect(frame, 15, 1), withAttributes: textFontAttributes)
        
        return frame
    }
    
}
