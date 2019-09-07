//
//  AppDelegate.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 27/08/2019.
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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var preferencesWindowController: NSWindowController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Swift.print("AppDelegate > applicationDidFinishLaunching")
        
        //Initialize value transformers
        let timeValueTransformer = TimeValueTransformer()
        let timeValueTransformerName = NSValueTransformerName.init("TimeValueTransformer")
        ValueTransformer.setValueTransformer(timeValueTransformer, forName: timeValueTransformerName)
        
        let markerCountValueTransformer = MarkerCountValueTransformer()
        let markerCountValueTransformerName = NSValueTransformerName.init("MarkerCountValueTransformer")
        ValueTransformer.setValueTransformer(markerCountValueTransformer, forName: markerCountValueTransformerName)
        
        let playlistImageValueController = PlaylistImageValueController()
        let playlistImageValueControllerName = NSValueTransformerName.init("PlaylistImageValueController")
        ValueTransformer.setValueTransformer(playlistImageValueController, forName: playlistImageValueControllerName)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func showPreferences(_ sender: Any) {
        if self.preferencesWindowController == nil {
            self.preferencesWindowController = NSStoryboard(name: "Preferences", bundle: nil).instantiateInitialController() as? NSWindowController
        }
        self.preferencesWindowController.showWindow(sender)
    }

}

