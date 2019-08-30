//
//  LeftViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class LeftViewController: NSViewController {
    
    @objc dynamic weak var windowController: WindowController!
    
    var displayedViewObservation: NSKeyValueObservation?
    
    @IBOutlet weak var tabView: NSTabView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Swift.print("LeftViewController > viewDidLoad")
    }
    
    func initialization() {
        Swift.print("LeftViewController > initialization()")
        
        if let window = self.view.window, let windowController = window.windowController {
            self.windowController = windowController as? WindowController
            
            let displayedViewPath = \WindowController.displayedView
            self.displayedViewObservation = self.windowController.observe(displayedViewPath) { [unowned self] object, change in
                let index = self.windowController.displayedView + 1
                self.tabView.selectTabViewItem(at: index)
            }
        }
    }
}
