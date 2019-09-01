//
//  MainSplitViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class MainSplitViewController: NSSplitViewController {
    
    weak var windowController: WindowController!
    
    var showAcousmoniumObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Swift.print("MainSplitViewController > viewDidLoad")
        
        //Fix acousmonium view item size properties
        self.splitViewItems[1].minimumThickness = 200
        self.splitViewItems[1].maximumThickness = 400
        self.splitViewItems[1].isCollapsed = true
        
    }
    
    func initialization() {
        Swift.print("MainSplitViewController > initialization()")
        
        (self.splitViewItems[0].viewController as! LeftViewController).initialization()
        
        if let window = self.view.window, let windowController = window.windowController {
            self.windowController = windowController as? WindowController
            let showAcousmoniumPath = \WindowController.showAcousmonium
            self.showAcousmoniumObservation = self.windowController.observe(showAcousmoniumPath) { [unowned self] object, change in
                self.splitViewItems[1].isCollapsed = self.windowController.showAcousmonium == .on ? false : true
            }
        }
    }
    
}
