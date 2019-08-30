//
//  NSButtonCounter.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class NSButtonCounter: NSButton {
    
    var counterValue: Float = 0 {
        didSet {
            (self.cell as! NSButtonCellCounter).counterValue = counterValue
            self.setNeedsDisplay()
        }
    }
    
    /**
     Blocking user actions
     */
    override func mouseDown(with theEvent: NSEvent) { }
    
}
