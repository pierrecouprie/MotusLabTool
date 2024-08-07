//
//  PlaylistViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 02/09/2019.
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

class PlaylistViewController: NSViewController {
    
    @objc dynamic weak var windowController: WindowController!
    
    @objc dynamic var playlistSelectedFileIndex: IndexSet! {
        didSet {
            self.windowController.playlistSelectedFileIndex = self.playlistSelectedFileIndex
        }
    }
    
    @objc dynamic var showImportingLabel: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setValue(self.windowController.playlistSelectedFileIndex, forKey: "playlistSelectedFileIndex")
    }
    
    // Prevent resizing sheet view
    override func viewWillLayout() {
        self.preferredContentSize = view.frame.size
    }
    
    @IBAction func addFiles(_ sender: Any) {
        let selectFilesPanel:NSOpenPanel = NSOpenPanel()
        selectFilesPanel.allowsMultipleSelection = true
        selectFilesPanel.canChooseDirectories = false
        selectFilesPanel.canCreateDirectories = false
        selectFilesPanel.canChooseFiles = true
        selectFilesPanel.allowedFileTypes = ["aif","aiff","wav","mp3","m4a"]
        
        selectFilesPanel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                self.windowController.addPlaylistFiles(selectFilesPanel.urls, playlistViewController: self)
            }
        }
    }
    
    @IBAction func removeFiles(_ sender: Any) {
        self.windowController.removeSelectedFiles()
    }
    
}
