//
//  MainSplitViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
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

class MainSplitViewController: NSSplitViewController {
    
    weak var windowController: WindowController!
    
    var showAcousmoniumObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Swift.print("MainSplitViewController > viewDidLoad")
        
        // Fix acousmonium view (at right) item size properties
        self.splitViewItems[1].minimumThickness = 200
        self.splitViewItems[1].maximumThickness = 900
        self.splitViewItems[1].isCollapsed = true
        
    }
    
    /// Initialization of each contained views
    func initialization() {
        Swift.print("MainSplitViewController > initialization()")
        
        (self.splitViewItems[0].viewController as! LeftViewController).initialization()
        (self.splitViewItems[1].viewController as! AcousmoniumViewController).initialization()
        (self.splitViewItems[0].viewController as! LeftViewController).acousmoniumViewController = self.splitViewItems[1].viewController as? AcousmoniumViewController
        
        // Add observer to show or hide (collapsed or not) acousmonium view in right
        if let window = self.view.window, let windowController = window.windowController {
            self.windowController = windowController as? WindowController
            let showAcousmoniumPath = \WindowController.showAcousmonium
            self.showAcousmoniumObservation = self.windowController.observe(showAcousmoniumPath) { [unowned self] object, change in
                self.splitViewItems[1].isCollapsed = self.windowController.showAcousmonium == .on ? false : true
            }
        }
    }
    
}
