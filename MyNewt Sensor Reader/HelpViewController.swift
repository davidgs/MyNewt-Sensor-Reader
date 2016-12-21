//
//  HelpViewController.swift
//  MyNewt Sensor Reader
//
//  Created by David G. Simmons on 12/21/16.
//  Copyright © 2016 Dragonfly IoT. All rights reserved.
//

import Cocoa

class HelpViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
         self.view.wantsLayer = true
        // Do view setup here.
    }
    override func awakeFromNib() {
        if self.view.layer != nil {
            let color : CGColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            self.view.layer?.backgroundColor = color
        }
        
    }
    
}
