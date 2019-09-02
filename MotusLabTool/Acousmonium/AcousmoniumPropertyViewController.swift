//
//  AcousmoniumPropertyViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 02/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class AcousmoniumPropertyViewController: NSViewController {
    
    @objc dynamic weak var windowController: WindowController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Swift.print("AcousmoniumPropertyViewController > viewDidLoad")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    @IBAction func addPreset(_ sender: Any) {
        self.windowController.createAcousmoniumFile("Untitled")
    }
    
    @IBAction func removePreset(_ sender: Any) {
        
    }
    
    //MARK: - Properties
    
    @IBAction func importImage(_ sender: Any) {
        let selectImagePanel:NSOpenPanel = NSOpenPanel()
        selectImagePanel.allowsMultipleSelection = false
        selectImagePanel.canChooseDirectories = false
        selectImagePanel.canCreateDirectories = false
        selectImagePanel.canChooseFiles = true
        selectImagePanel.allowedFileTypes = ["jpg","jpeg","png"]
        
        selectImagePanel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let url = selectImagePanel.urls.first, let selectedAcousmoniumFile = self.windowController.selectedAcousmoniumFile {
                    do {
                        let image = try Data(contentsOf: url)
                        selectedAcousmoniumFile.setValue(image, forKey: AcousmoniumFile.PropertyKey.imageKey)
                    } catch let error as NSError {
                        Swift.print("AcousmoniumPropertyViewController: importImage() Error openning url \(url), context: " + error.localizedDescription)
                    }
                    
                }
            }
        }
    }
    
    //MARK: - HP list
    
    @IBAction func addLoudspeaker(_ sender: Any) {
        if let selectedAcousmoniumFile = self.windowController.selectedAcousmoniumFile {
            selectedAcousmoniumFile.createLoudspeaker()
        }
    }
    
    @IBOutlet weak var tableView: NSTableView!
    @IBAction func removeLoudspeaker(_ sender: Any) {
        let index = self.tableView.selectedRow
        if let selectedAcousmoniumFile = self.windowController.selectedAcousmoniumFile {
            if index > -1 && index < selectedAcousmoniumFile.acousmoLoudspeakers.count {
                let loudspeaker = selectedAcousmoniumFile.acousmoLoudspeakers[index]
                selectedAcousmoniumFile.removeLoudspeaker(loudspeaker)
            }
        }
    }
}
