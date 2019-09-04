//
//  PlaylistViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 02/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class PlaylistViewController: NSViewController {
    
    @objc dynamic weak var windowController: WindowController!
    
    @IBAction func addFiles(_ sender: Any) {
        let selectFilesPanel:NSOpenPanel = NSOpenPanel()
        selectFilesPanel.allowsMultipleSelection = true
        selectFilesPanel.canChooseDirectories = false
        selectFilesPanel.canCreateDirectories = false
        selectFilesPanel.canChooseFiles = true
        selectFilesPanel.allowedFileTypes = ["aif","aiff","wav","mp3"]
        
        selectFilesPanel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                self.windowController.addPlaylistFiles(selectFilesPanel.urls)
            }
        }
    }
    
    @IBAction func removeFiles(_ sender: Any) {
        self.windowController.removeSelectedFiles()
    }
    
}
