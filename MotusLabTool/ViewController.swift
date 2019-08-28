//
//  ViewController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 27/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var containerView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    
    func changeMode(_ mode: String) {
        if mode == Mode.record {
            Swift.print("Record")
        } else {
            Swift.print("Play")
        }
    }


}

