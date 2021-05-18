//
//  PreferencesWindowController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 15/05/2021.
//  Copyright © 2021 Pierre Couprie. All rights reserved.
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

class PreferencesWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        
        // Initialize toolbar properties
        self.window?.toolbar?.sizeMode = .small
        self.window?.toolbar?.displayMode = .iconOnly
        
        // Initialize window properties
        let size = CGSize(width: 386, height: 467)
        let contentFrame = (self.window?.frameRect(forContentRect: NSMakeRect(0.0, 0.0, size.width, size.height)))!
        var frame = (self.window?.frame)!
        frame.origin.y = frame.origin.y + (frame.size.height - contentFrame.size.height)
        frame.size.height = contentFrame.size.height;
        frame.size.width = contentFrame.size.width;
        self.window?.setFrame(frame, display: false, animate: false)
        
    }
    
}
