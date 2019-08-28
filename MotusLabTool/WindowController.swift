//
//  WindowController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 28/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    
    @IBOutlet weak var toolbarMode: NSSegmentedControl!
    @IBAction func changeMode(_ sender: Any) {
        if let contentViewController = self.contentViewController, let viewController = contentViewController as? ViewController {
            viewController.changeMode(Mode.modeFrom((sender as! NSSegmentedControl).indexOfSelectedItem))
        }
    }
    
}
