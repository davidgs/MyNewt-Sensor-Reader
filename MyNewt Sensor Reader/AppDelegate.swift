/*
  AppDelegate.swift
  MyNewt Sensor Reader

  Created by David G. Simmons on 12/20/16.
  Copyright © 2016 Dragonfly IoT. All rights reserved.

 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

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

