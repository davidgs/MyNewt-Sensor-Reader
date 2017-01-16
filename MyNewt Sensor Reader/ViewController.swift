/*
*  ViewController.swift
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

class ViewController: NSViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var deviceNameLabel: NSTextField!
    
    @IBOutlet weak var scanProgress: NSProgressIndicator!
    @IBOutlet weak var helpButton: NSButton!
    @IBOutlet weak var rssiButton: NSButton!
    @IBOutlet weak var stayConnected: NSButton!
    @IBOutlet weak var disconnectButton: NSButton!
    @IBOutlet weak var myNewtTableView: NSTableView!
    @IBOutlet var myNewtArrayController: NSArrayController!
    
    
    lazy var prefsController: NSViewController = {
        return self.storyboard!.instantiateController(withIdentifier: "prefsView")
            as! NSViewController
    }()
    var scanStory: NSStoryboard = NSStoryboard.init(name: "Scan", bundle: nil)
    var scanViewController: NSViewController = {
        var s = NSStoryboard.init(name: "Scan", bundle: nil).instantiateInitialController() as! NSWindowController
           return s.contentViewController!
    }()
    
    dynamic var newtSensors = [MyNewtSensor]()

    var alwaysConn : Bool = false
    var isConnected : Bool = false
    var isScanning : Bool = false
    var showRSSIVal : Bool = false
    
    let prefs = UserDefaults.standard
    var centralManager : CBCentralManager!
    var myNewtPeripheral : CBPeripheral!
    
    var myTimer: Timer!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNotificationSentLabel), name: NSNotification.Name(rawValue: myNotification), object: nil)
        centralManager = CBCentralManager.init(delegate: self, queue: nil, options: nil)
        self.isScanning = true
        // Do any additional setup after loading the view.
        // Set up title label
        statusLabel.stringValue = "Loading..."
        self.disconnectButton.title = "Stop"
        // Do any additional setup after loading the view.
    }
    
    func updateNotificationSentLabel() {
        print("Notification received!")
        self.loadPrefs()
        reconnect()
    }

    override func awakeFromNib() {
        if self.view.layer != nil {
            let color : CGColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            self.view.layer?.backgroundColor = color
        }
        
    }
    
    @IBAction func unwindToThisViewController(segue: NSStoryboardSegue) {
        print("Unwound!")
        //Insert function to be run upon dismiss of VC2
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewWillAppear() {
        print("Appearing ...")
    }
    
    //Add the RSSI Reading to the Table
    @IBAction func rssiButtonAction(_ sender: Any) {
        showRSSIVal = !showRSSIVal
        if(showRSSIVal){
            let newSensor = MyNewtSensor(sensorName: "RSSI Signal Strength", nUUID : "RSSI", dUUID : "dRSSI", sensorValue : -00)
            newtSensors.insert(newSensor, at: 0)
            
        } else {
            newtSensors.remove(at: 0)
        }
    }

    // set stay Conected
    @IBAction func stayConnectedAction(_ sender: Any) {
        if(self.stayConnected.state == NSOnState) {
            self.alwaysConn = true
        } else {
            self.alwaysConn = false
        }
    }

    // show help
    @IBAction func helpButtonAction(_ sender: Any) {
    }
    
    // disconnect MyNewts
    @IBAction func disconnectButtonAction(_ sender: Any) {
        reconnect()

    }
    
    @IBAction func searchButtonAction(_ sender: Any) {
        // show the search sheet
        stopAll()
        savePrefs()
        self.presentViewControllerAsSheet(scanViewController)
    }
    
    
    // settingsButton
    @IBAction func settingsButtonAction(_ sender: Any) {
        print("Settings ... ")
        //disconnect, then show
        stopAll()
        savePrefs()
        self.presentViewControllerAsSheet(prefsController)
    }
    
    
    //save user prefs
    func savePrefs(){
        let prefs = UserDefaults.standard
        prefs.set(myNewt.subscribeAll, forKey: "subscribeAll")
        prefs.set(myNewt.exactMatch, forKey: "exactMatch")
        prefs.set(myNewt.MyNewtSensorServiceUUID.uuidString, forKey: "serviceUUID")
        prefs.set(myNewt.configPrefix, forKey: "configPrefix")
        prefs.set(myNewt.dataPrefix, forKey: "dataPrefix")
        prefs.set(myNewt.deviceName, forKey: "deviceName")
        prefs.set(self.alwaysConn, forKey: "alwaysConnected")
        prefs.set(myNewt.rssiUpdate, forKey: "rssiUpdate")

    }
    
    //load user prefs
    func loadPrefs(){
        print("loading prefs")
        if(prefs.bool(forKey: "alwaysConnected")){
            self.stayConnected.state = NSOnState
            self.alwaysConn = true
        }
        myNewt.subscribeAll = prefs.bool(forKey: "subscribeAll")
        myNewt.exactMatch = prefs.bool(forKey: "exactMatch")
        myNewt.MyNewtSensorServiceUUID = CBUUID(string: prefs.string(forKey: "serviceUUID")!)
        myNewt.configPrefix = prefs.string(forKey: "configPrefix")!
        myNewt.dataPrefix = prefs.string(forKey: "dataPrefix")!
        myNewt.deviceName = prefs.string(forKey: "deviceName")!
        myNewt.rssiUpdate = prefs.integer(forKey: "rssiUpdate")
        
        

    }
    
    // reconnect to devices
    func reconnect(){
        if(self.isConnected){
            //disconnect
            self.disconnectButton.title = "Re-Scan"
            self.isScanning = false
            self.isConnected = false
            centralManager.cancelPeripheralConnection(self.myNewtPeripheral)
            newtSensors = [MyNewtSensor]()
            self.rssiButton.image = NSImage(named: "NoSignal-sm")!
            self.deviceNameLabel.stringValue = "None"
        }
        else if( self.isScanning){
            centralManager.stopScan()
            self.isScanning = false
            self.scanProgress.stopAnimation(self)
            self.disconnectButton.title = "Re-Scan"
            self.rssiButton.image = NSImage(named: "NoSignal-sm")!
            self.deviceNameLabel.stringValue = "None"
        }
        else {
            self.disconnectButton.title = "Stop"
            self.isScanning = true
            self.scanProgress.startAnimation(self)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            if(showRSSIVal){
                let newSensor = MyNewtSensor(sensorName: "RSSI Signal Strength", nUUID : "RSSI", dUUID : "dRSSI", sensorValue : -00)
                newtSensors.insert(newSensor, at: 0)
            }
        }
    }
    // shut all connections down
    func stopAll(){
        if(self.isConnected){
            //disconnect
            self.disconnectButton.title = "Re-Scan"
            self.isScanning = false
            self.isConnected = false
            centralManager.cancelPeripheralConnection(self.myNewtPeripheral)
            centralManager.stopScan()
            newtSensors = [MyNewtSensor]()
            self.rssiButton.image = NSImage(named: "NoSignal-sm")!
            self.deviceNameLabel.stringValue = "None"
            if(myTimer != nil && myTimer.isValid){
                myTimer.invalidate()
            }
        }
        else if( self.isScanning){
            centralManager.stopScan()
            self.isScanning = false
            self.scanProgress.stopAnimation(self)
            self.disconnectButton.title = "Re-Scan"
            self.rssiButton.image = NSImage(named: "NoSignal-sm")!
            self.deviceNameLabel.stringValue = "None"
            if(myTimer != nil && myTimer.isValid){
                myTimer.invalidate()
            }
        }

    }
    
    
    /******* CBCentralManagerDelegate *******/
    
    // Check status of BLE hardware
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBCentralManagerState.poweredOn {
            // Scan for peripherals if BLE is turned on
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            self.scanProgress.startAnimation(self)
            self.statusLabel.stringValue = "Searching for Mynewt Devices..."
        }
        else {
            // Can have different conditions for all states if needed -- punt for now
        }
    }
    
    
    // Check out the discovered peripherals to find a MyNewt Device
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        print("AdvertisementData: \(advertisementData)")
        print("Services: \(peripheral.services) State: \(peripheral.state) Identifier: \(peripheral.identifier) Name: \(peripheral.name)")
        if myNewt.MyNewtDevFound(advertisementData: advertisementData as [NSObject : AnyObject]!) == true {
            self.isScanning = false
            self.isConnected = true
            self.disconnectButton.title = "Disconnect"
            // Update Status Label
            self.statusLabel.stringValue = "Mynewt Device Found"
            self.scanProgress.stopAnimation(self)
            self.deviceNameLabel.stringValue = myNewt.deviceString
            // Stop scanning, set as the peripheral to use and establish connection
            self.centralManager.stopScan()
            self.myNewtPeripheral = peripheral
            self.myNewtPeripheral.delegate = self
            self.centralManager.connect(peripheral, options: nil)
            let interval = Double.init(prefs.integer(forKey: "rssiUpdate"))
            
            myTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(readRSSI), userInfo: nil, repeats: true)
        }
    }
    
    // Discover services of the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.statusLabel.stringValue = "Discovering Mynewt peripheral services"
        peripheral.discoverServices(nil)
    }
    
    
    // If disconnected, start searching again
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.statusLabel.stringValue = "Disconnected"
        self.disconnectButton.title = "Re-Scan"
        // central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    /******* CBCentralPeripheralDelegate *******/
    
    // Check if the service discovered is valid
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.statusLabel.stringValue = "Looking at Mynewt peripheral services"
        for service in peripheral.services! {
            let thisService = service as CBService
            print(thisService)
            if myNewt.validService(service: thisService) {
                
                // Discover characteristics of all valid services
                peripheral.discoverCharacteristics(nil, for: thisService)
            }
        }
    }
    
    
    // Enable notification and sensor for each characteristic of valid service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        self.statusLabel.stringValue = "Enabling Mynewt sensors"
        for charateristic in service.characteristics! {
            let thisCharacteristic = charateristic as CBCharacteristic
            print(thisCharacteristic)
            if(myNewt.subscribeAll){
                if(myNewt.isNotifyCharacteristic(characteristic: thisCharacteristic)){
                    self.myNewtPeripheral.setNotifyValue(true, for: thisCharacteristic)
                }
            } else {
                if myNewt.validDataCharacteristic(characteristic: thisCharacteristic) {
                    // Enable Sensor Notification
                    self.myNewtPeripheral.setNotifyValue(true, for: thisCharacteristic)
                }
                if myNewt.validConfigCharacteristic(characteristic: thisCharacteristic) {
                    
                    myNewtPeripheral.readValue(for: thisCharacteristic)
                }
            }
        }
        
    }
    
    
    
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        let rssi = abs(peripheral.rssi as! Int32)
        if(rssi < 70){
            self.rssiButton.image = NSImage(named: "FourBars-sm")!
        } else if (rssi < 80) {
            self.rssiButton.image = NSImage(named: "ThreeBars-sm")!
        } else if (rssi < 90) {
            self.rssiButton.image = NSImage(named: "TwoBars-sm")!
        } else if(rssi < 100) {
            self.rssiButton.image = NSImage(named: "OneBar-sm")!
        } else {
            self.rssiButton.image = NSImage(named: "NoSignal-sm")!
        }
        if(self.showRSSIVal){
            let r = peripheral.rssi as! Double
            newtSensors[0].setValue(r, forKey: "sensorValue")
            print("Updating RSSI: \(r)")
            
        }
        
    }
    
    func readRSSI() {
        if (myNewtPeripheral != nil) {
            myNewtPeripheral.delegate = self
            //  print("RSSI Request - \(self.myNewtPeripheral.name!)")
            myNewtPeripheral.readRSSI()
        } else {
            print("peripheral = nil")
        }
    }
    
    
    
    // Get data values when they are updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        self.statusLabel.stringValue = "Connected"
        self.deviceNameLabel.stringValue = peripheral.name!
        let b = MyNewtDev.getAmbientTemperature(value: characteristic.value! as NSData)
        if(b == nil) {
            return
        }
        print("Characteristic: \(characteristic.uuid.uuidString) Value: \(b)")
        let charType = characteristic.uuid.uuidString.substring(to: characteristic.uuid.uuidString.index(characteristic.uuid.uuidString.startIndex, offsetBy: 2))
        
        let charVal = characteristic.uuid.uuidString.substring(from: characteristic.uuid.uuidString.index(characteristic.uuid.uuidString.startIndex, offsetBy: 2))
        let uuid = characteristic.uuid.uuidString
        // self.readRSSI()
        for i in 0..<newtSensors.count {
            if(newtSensors[i].containsValue(value: uuid)) {
                newtSensors[i].updateValue(key: uuid, value: characteristic.value!)
                newtSensors[i].setValue(MyNewtDev.getAmbientTemperature(value: characteristic.value! as NSData), forKey: "sensorValue")
                return
            }
        }
            // never seen this before
            if(myNewt.subscribeAll){
                let newSensor = MyNewtSensor(sensorName: "Sensor Data UUID: 0x\(characteristic.uuid.uuidString)", nUUID : characteristic.uuid.uuidString, dUUID : characteristic.uuid.uuidString, sensorValue : 0.00)
                newtSensors.append(newSensor)
            } else {
                switch charType {
                case "DE":
                    let newSensor = MyNewtSensor(sensorName: String(bytes: characteristic.value!, encoding: String.Encoding.utf8)!, nUUID : characteristic.uuid.uuidString, dUUID : "BE" + charVal, sensorValue : 0.00)
                    newtSensors.append(newSensor)
                default:
                    break
                }
            }
    }

}

