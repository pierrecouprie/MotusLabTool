//
//  AppDelegate.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 27/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var preferencesWindowController: NSWindowController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Swift.print("AppDelegate > applicationDidFinishLaunching")
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

