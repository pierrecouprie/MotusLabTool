//
//  AcousmoniumViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 02/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class AcousmoniumViewController: NSViewController {
    
    @objc dynamic weak var windowController: WindowController!
    @IBOutlet weak var acousmoniumView: AcousmoniumView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Swift.print("AcousmoniumViewController > viewDidLoad")
    }
    
    func initialization() {
        Swift.print("AcousmoniumViewController > initialization()")
        if let window = self.view.window, let windowController = window.windowController {
            self.windowController = windowController as? WindowController
            self.acousmoniumView.windowController = self.windowController
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let windowController = segue.destinationController as? NSWindowController, let acousmoniumPropertyViewController = windowController.contentViewController as? AcousmoniumPropertyViewController {
            acousmoniumPropertyViewController.windowController = self.windowController
        }
    }
    
}
