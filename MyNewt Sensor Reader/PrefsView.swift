/*
*  PrefsView.swift
*  MyNewt Sensor Reader
*
*  Created by David G. Simmons on 12/20/16.
*  Copyright © 2016 Dragonfly IoT. All rights reserved.
*
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
import CoreBluetooth

class PrefsView: NSViewController {

    @IBOutlet weak var hostNameField: NSTextField!
    @IBOutlet weak var serviceUUIDField: NSTextField!
    @IBOutlet weak var configPrefixField: NSTextField!
    @IBOutlet weak var dataPrefixField: NSTextField!
    @IBOutlet weak var exactMatchButton: NSButton!
    @IBOutlet weak var subscribeAllButton: NSButton!
    @IBOutlet weak var rssiRefreshVal: NSTextField!
    @IBOutlet weak var rssiChanger: NSStepper!
    
    let prefs = UserDefaults.standard

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear() {
        loadPrefs()
    }
    
    //make the view white-backgrounded
    override func awakeFromNib() {
        if self.view.layer != nil {
            let color : CGColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            self.view.layer?.backgroundColor = color
        }
        
        
    }
    
    @IBAction func rssiRefreshChange(_ sender: NSStepper) {
        let val : Int = sender.integerValue
        myNewt.setRSSIUpdate(interval: val)
        self.rssiRefreshVal.stringValue = sender.stringValue
    }
    
    func notify() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: myNotification), object: self)
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        notify()
        self.dismiss(self)
    }
    
    
    @IBAction func okButtonAction(_ sender: Any) {
        // save all prefs
        savePrefs()
        notify()
        self.dismiss(self)
    }
    
    func loadPrefs(){
        if let lastDev = prefs.string(forKey: "deviceName"){
            print("The user has a defined Device Name: " + lastDev)
            myNewt.setDeviceName(name: lastDev)
            if(lastDev != "nimble") {
                self.hostNameField.stringValue = lastDev
            }
        }
        if let dataPrefix = prefs.string(forKey: "dataPrefix"){
            myNewt.dataPrefix = dataPrefix
            print("Data Prefix: \(dataPrefix)")
            if(dataPrefix != "BE") {
                self.dataPrefixField.stringValue = dataPrefix
            }
        }
        if let configPrefix = prefs.string(forKey: "configPrefix"){
            myNewt.configPrefix = configPrefix
            print("Config Prefix: \(configPrefix)")
            if(configPrefix != "DE"){
                self.configPrefixField.stringValue = configPrefix
            }
        }
        if let serviceUUID = prefs.string(forKey: "serviceUUID"){
            myNewt.MyNewtSensorServiceUUID = CBUUID(string: serviceUUID)
            print("Service UUID: \(serviceUUID)")
            if(serviceUUID != "E761D2AF-1C15-4FA7-AF80-B5729020B340") {
                self.serviceUUIDField.stringValue = serviceUUID
            }
        }
        myNewt.subscribeAll = prefs.bool(forKey: "subscribeAll")
        print("Subscribe all: \(prefs.bool(forKey: "subscribeAll"))")
        if(prefs.bool(forKey: "subscribeAll")){
            self.subscribeAllButton.state = NSOnState
        }
        if(prefs.bool(forKey: "exactMatch")){
            self.exactMatchButton.state = NSOnState
        }
        myNewt.exactMatch = prefs.bool(forKey: "exactMatch")
        print("exact match: \(prefs.bool(forKey: "exactMatch"))")
        rssiChanger.setValue(prefs.integer(forKey: "rssiUpdate"), forKey: "IntegerValue")
        // self.rssiChanger.setValue()
        self.rssiRefreshVal.stringValue = rssiChanger.stringValue
        
    }

    func savePrefs(){
        let prefs = UserDefaults.standard
        prefs.set((self.subscribeAllButton.state == NSOnState), forKey: "subscribeAll")
        prefs.set((self.exactMatchButton.state == NSOnState), forKey: "exactMatch")
        if(self.serviceUUIDField.stringValue != "" && self.serviceUUIDField.stringValue != "E761D2AF-1C15-4FA7-AF80-B5729020B340"){
            prefs.set(self.serviceUUIDField.stringValue, forKey: "serviceUUID")

        }
        if(self.configPrefixField.stringValue != "" && self.configPrefixField.stringValue != "DE"){
            prefs.set(self.configPrefixField.stringValue, forKey: "configPrefix")
        }
        if(self.dataPrefixField.stringValue != "" && self.dataPrefixField.stringValue != "BE"){
            prefs.set(self.dataPrefixField.stringValue, forKey: "dataPrefix")
        }
        if(self.hostNameField.stringValue != "" && self.hostNameField.stringValue != "nimble"){
            prefs.set(self.hostNameField.stringValue, forKey: "deviceName")
        }
        prefs.set(self.rssiChanger.integerValue, forKey: "rssiUpdate")
        
    }
    
    
}

