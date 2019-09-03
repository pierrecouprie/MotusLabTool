//
//  Window.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 31/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class Window: NSWindow {
    
    /// Use keyboard to control playback
    override func keyDown(with event: NSEvent) {
        
        if let windowController = self.windowController {
            
            if (windowController as! WindowController).displayedView == 2 {
                
                // Space bar
                if event.keyCode == 49 {
                    if (windowController as! WindowController).toolbarPlay == .off {
                        (windowController as! WindowController).toolbarPlay = .on
                        (windowController as! WindowController).leftViewController.startPlaying()
                    } else {
                        (windowController as! WindowController).toolbarPlay = .off
                        (windowController as! WindowController).leftViewController.pausePlaying()
                    }
                    
                //<-
                } else if event.keyCode == 123 {
                    (windowController as! WindowController).leftViewController.prev()
                    
                //->
                } else if event.keyCode == 124 {
                    (windowController as! WindowController).leftViewController.next()
                }
                
            }
            
        }
            
        super.keyDown(with: event)
    }
    
}
