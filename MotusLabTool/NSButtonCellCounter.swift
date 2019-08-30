//
//  NSButtonCellCounter.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class NSButtonCellCounter: NSButtonCell {
    
    /*
     image = NSRect: {{279, 8.5}, {14, 14}}
     texte = NSRect: {{9, 7}, {266, 17}}
     */
    
    var counterValue: Float = 0
    
    /**
     Formating the string to draw from :
     - counterValue
     - filename
     */
    func createCounterText() -> String {
        let counterStr: String = self.counterValue.floatToTime()
        return counterStr
    }
    
    /**
     Drawing the string and images
     */
    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
        
        //I draw the Counter
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
