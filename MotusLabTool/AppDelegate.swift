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
        
        // Initialize value transformers
        let timeValueTransformer = TimeValueTransformer()
        let timeValueTransformerName = NSValueTransformerName.init("TimeValueTransformer")
        ValueTransformer.setValueTransformer(timeValueTransformer, forName: timeValueTransformerName)
        
        let simpleTimeValueTransformer = SimpleTimeValueTransformer()
        let simpleTimeValueTransformerName = NSValueTransformerName.init("SimpleTimeValueTransformer")
        ValueTransformer.setValueTransformer(simpleTimeValueTransformer, forName: simpleTimeValueTransformerName)
        
        let markerCountValueTransformer = MarkerCountValueTransformer()
        let markerCountValueTransformerName = NSValueTransformerName.init("MarkerCountValueTransformer")
        ValueTransformer.setValueTransformer(markerCountValueTransformer, forName: markerCountValueTransformerName)
        
        let nsbuttonStateIntegerValueTransformer = NSButtonStateIntegerValueTransformer()
        let nsbuttonStateIntegerValueTransformerName = NSValueTransformerName.init("NSButtonStateIntegerValueTransformer")
        ValueTransformer.setValueTransformer(nsbuttonStateIntegerValueTransformer, forName: nsbuttonStateIntegerValueTransformerName)
        
        let recordingValueTransformer = RecordingValueTransformer()
        let recordingValueTransformerName = NSValueTransformerName.init("RecordingValueTransformer")
        ValueTransformer.setValueTransformer(recordingValueTransformer, forName: recordingValueTransformerName)
        
        let secondsValueTransformer = SecondsValueTransformer()
        let secondsValueTransformerName = NSValueTransformerName.init("SecondsValueTransformer")
        ValueTransformer.setValueTransformer(secondsValueTransformer, forName: secondsValueTransformerName)
        
        let syncValueTransformer = SyncValueTransformer()
        let syncValueTransformerName = NSValueTransformerName.init("SyncValueTransformer")
        ValueTransformer.setValueTransformer(syncValueTransformer, forName: syncValueTransformerName)
        
        let unarchiveColorFromDataValueTransformer = UnarchiveColorFromDataValueTransformer()
        let unarchiveColorFromDataValueTransformerName = NSValueTransformerName.init("UnarchiveColorFromDataValueTransformer")
        ValueTransformer.setValueTransformer(unarchiveColorFromDataValueTransformer, forName: unarchiveColorFromDataValueTransformerName)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) { }
    
    /// Open file by double click or drag to icon
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        if let windowController = NSApplication.shared.mainWindow?.windowController {
            var url = URL(fileURLWithPath: filenames.first!)
            if url.pathExtension == FileExtension.motuslab {
                (windowController as! WindowController).openMotusLabFile(url)
            } else {
                for filename in filenames {
                    url = URL(fileURLWithPath: filename)
                    if url.pathExtension == FileExtension.acousmonium {
                        (windowController as! WindowController).importAcousmoniumFile(url)
                    }
                }
            }
        }
    }
    
    /// Open window of preferences
    @IBAction func showPreferences(_ sender: Any) {
        if self.preferencesWindowController == nil {
            self.preferencesWindowController = NSStoryboard(name: "Preferences", bundle: nil).instantiateInitialController() as? NSWindowController
        }
        self.preferencesWindowController.showWindow(sender)
    }

}

