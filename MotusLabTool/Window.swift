//
//  Window.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 31/08/2019.
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

class Window: NSWindow {
    
    /// Use keyboard to control playback
    override func keyDown(with event: NSEvent) {
        
        if let windowController = self.windowController {
                
            // Space bar
            if event.keyCode == 49 {
                if (windowController as! WindowController).displayedView == 1 { //Record interface
                    if UserDefaults.standard.bool(forKey: PreferenceKey.usePlaylist) {
                        if (windowController as! WindowController).toolbarPlay == .off {
                            (windowController as! WindowController).toolbarPlay = .on
                            (windowController as! WindowController).leftViewController.startPlayingPlaylist()
                        } else {
                            (windowController as! WindowController).toolbarPlay = .off
                            (windowController as! WindowController).leftViewController.pausePlayingPlaylist()
                        }
                    }
                    /*if (windowController as! WindowController).toolbarRecord == .off {
                        (windowController as! WindowController).toolbarRecord = .on
                        (windowController as! WindowController).leftViewController.startRecording()
                    } else {
                        (windowController as! WindowController).toolbarRecord = .off
                        (windowController as! WindowController).leftViewController.stopRecording()
                    }*/
                } else if (windowController as! WindowController).displayedView == 2 { //Play interface
                    if (windowController as! WindowController).toolbarPlay == .off {
                        (windowController as! WindowController).toolbarPlay = .on
                        (windowController as! WindowController).leftViewController.startPlaying()
                    } else {
                        (windowController as! WindowController).toolbarPlay = .off
                        (windowController as! WindowController).leftViewController.stopPlaying(pause: true)
                    }
                }
                // <- (left arrow)
            } else if event.keyCode == 123 {
                if (windowController as! WindowController).displayedView == 2 {
                    (windowController as! WindowController).leftViewController.prev()
                }
                
                // -> (right arrow)
            } else if event.keyCode == 124 {
                if (windowController as! WindowController).displayedView == 2 {
                    (windowController as! WindowController).leftViewController.next()
                }
            }
            
        }
            
        super.keyDown(with: event)
    }
    
}
