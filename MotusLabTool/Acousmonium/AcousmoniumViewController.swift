//
//  AcousmoniumViewController.swift
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

class AcousmoniumViewController: NSViewController {
    
    @objc dynamic weak var windowController: WindowController!
    @IBOutlet weak var acousmoniumView: AcousmoniumView!
    
    func initialization() {
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
