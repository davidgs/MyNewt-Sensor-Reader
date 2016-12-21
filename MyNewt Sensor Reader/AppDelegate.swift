//
//  AppDelegate.swift
//  MyNewt Sensor Reader
//
//  Created by David G. Simmons on 12/20/16.
//  Copyright © 2016 Dragonfly IoT. All rights reserved.
//

import Cocoa

let myNewt = MyNewtDev()
let myNotification = "com.dragonflyiot.endedit"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    @IBOutlet weak var window: NSWindow!
    let myViewController : ViewController = ViewController()
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        self.window?.delegate = self
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        print("terminating ...")
        let newt = NSApp?.windows[0].contentViewController as! ViewController
        newt.savePrefs()
        if(!newt.alwaysConn){
            newt.stopAll()
        }
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        print("Going Active")
        let newt = NSApp?.windows[0].contentViewController as! ViewController
        newt.loadPrefs()
        if(!newt.alwaysConn){
            newt.reconnect()
        }
        
    }
    
       
    func applicationDidResignActive(_ notification: Notification) {
        print("Going inactive")
        //   let pres =  self. contentViewController?.presenting
        let newt = NSApp?.windows[0].contentViewController as! ViewController
        newt.savePrefs()
        if(!newt.alwaysConn){
            newt.stopAll()
        }
        
    }
    
    

}

