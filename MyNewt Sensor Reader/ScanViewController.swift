/*
 *  ScanViewController.swift
 *  MyNewt Sensor Reader
 *
 * Created by David G. Simmons on 12/20/16.
 * Copyright © 2016 Dragonfly IoT. All rights reserved.
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

class ScanViewController: NSViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NSOutlineViewDelegate, TreeNode {

    var stepper = 0
    var name = "Bluetooth Devices"
    var serviceID = ""
    var deviceStore = [TreeNode]()
    @IBOutlet var treeController: NSTreeController!
    @IBOutlet weak var outlineView: NSOutlineView!
    var deviceManager : CBCentralManager!
    var peripheral : CBPeripheral!
    var conPeriph : String!
    var connService : String!
    var periphIndex : Int!

    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var okButton: NSButtonCell!
    @IBOutlet weak var scanStatus: NSProgressIndicator!

   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.treeController.content = self
        self.treeController.preservesSelection = true
       
    }
    
    override func awakeFromNib() {
        if self.view.layer != nil {
            let color : CGColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            self.view.layer?.backgroundColor = color
        }
        
        
    }
    
    override func viewWillAppear() {
        print("Appearing ...")
        self.deviceManager = CBCentralManager(delegate: self, queue: nil)
        self.outlineView.delegate = self
        self.scanStatus.startAnimation(self)

    }

    override func viewWillDisappear() {
        self.deviceManager.stopScan()
        self.deviceStore = [TreeNode]()
        self.treeController.rearrangeObjects()
        self.outlineView.reloadData()
        self.outlineView.setNeedsDisplay()
    }
    
    func notify() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: myNotification), object: self)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    

    @IBAction func okAction(_ sender: Any) {
        self.deviceManager.stopScan()
        myNewt.setDeviceName(name: self.conPeriph)
        myNewt.setServiceUUID(uuid: self.connService)
        myNewt.setSubAll(subscribe: true)
        myNewt.setExactMatch(match: true)
        myNewt.savePrefs()
        self.dismiss(self)
        notify()

    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.deviceManager.stopScan()
        self.dismiss(self)
        notify()
    }
    
    
    /******Bluetooth*********/
    /******* CBCentralManagerDelegate *******/
    
    // Check status of BLE hardware
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBCentralManagerState.poweredOn {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripherals(withServices: nil, options: nil)
        }
        else {
            // Can have different conditions for all states if needed - show generic alert for now
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let nameOfDeviceFound = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
        let myUUID = CBUUID(nsuuid: peripheral.identifier)
        print("AD DATA: \(nameOfDeviceFound) UUID: \(myUUID.uuidString)")
        if(nameOfDeviceFound != nil){
            var seen = false
            for i in 0..<deviceStore.count {
              if(deviceStore[i].containsName(name: nameOfDeviceFound as! String) || deviceStore[i].containsUUID(uuid: myUUID)){
                      seen = true
                    break
                 }
               }
            if(!seen) {
                let dev = Device(name: nameOfDeviceFound as! String, id: myUUID.uuidString)
                dev.peripheral = peripheral
                deviceStore.append(dev)
                deviceManager.connect(peripheral, options: nil)
                self.treeController.rearrangeObjects()
                self.outlineView.reloadData()
                self.outlineView.setNeedsDisplay()
            }
            self.statusLabel.stringValue = "Select Bluetooth Device"
        }
    }
    
    // Discover services of the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to device: \(peripheral.name)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    
    // If disconnected, start searching again
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected")
        deviceManager.scanForPeripherals(withServices: nil, options: nil)
        print("Restarting scan for devices ...")
    }
    
    /******* CBCentralPeripheralDelegate *******/
    
    // Check if the service discovered is valid
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        var index : Int!
        var dev : Device!
        for i in 0..<deviceStore.count {
            if(deviceStore[i].containsName(name: peripheral.name!)){
                index = i
                dev = deviceStore[i] as! Device
                break
            }
        }
        for service in peripheral.services! {
            let thisService = service as CBService
            let serv = Service(name: "Service: ", id: thisService.uuid.uuidString)
            dev.serviceStore.append(serv)
            deviceStore.remove(at: index)
            deviceStore.insert(dev, at: index)
        }
        self.treeController.rearrangeObjects()
        self.outlineView.reloadData()
        self.outlineView.setNeedsDisplay()
        deviceManager.cancelPeripheralConnection(peripheral)
    }
    
    
    // Enable notification and sensor for each characteristic of valid service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Discovered Characteristics")
    }
    
    
    
    // Get data values when they are updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        peripheral.readRSSI()
    }
    
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        _ = abs((peripheral.rssi?.intValue)! )
        print("Scan RSSI: \(peripheral.rssi?.intValue)")
    }
    
    /*****OutlineView********/
    
    // NSOutlineViewDelegate
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        self.okButton.isEnabled = false
        //print(notification)
        let selectedIndex = (notification.object as AnyObject).selectedRow!
        let selCol1 = outlineView.view(atColumn: 0, row: selectedIndex, makeIfNecessary: false)?.subviews.last as! NSTextField
        let selCol2 = outlineView.view(atColumn: 1, row: selectedIndex, makeIfNecessary: false)?.subviews.last as! NSTextField
        
        let devName = selCol1.stringValue
        let devID = selCol2.stringValue
        print("Selected Device Name - \(devName) ServiceID: \(devID)")
        let thisUUID = CBUUID(string: devID)
        switch devName {
        case "Service: " :
            //print("This is a service")
            for i in 0..<deviceStore.count {
                let dev = deviceStore[i] as! Device
                for x in 0..<dev.serviceStore.count {
                    if(dev.serviceStore[x].containsUUID(uuid: thisUUID)) {
                        //found it!
                        print("Found Device: \(dev.name) ID: \(dev.serviceID) Service ID\(devID)")
                        self.conPeriph = dev.name
                        self.connService = devID
                        self.okButton.isEnabled = true
                        self.scanStatus.stopAnimation(self)
                        return
                    }
                }
            }
            break
        default :
            //print("This is a Device")
            break
        }
    }
    
    /*****TreeNode Protocol*****/
     var isLeaf:Bool {
        return deviceStore.isEmpty
    }
    var childCount:Int {
        return deviceStore.count
    }
    var children:[TreeNode] {
        return deviceStore
    }
    func containsName(name: String) -> Bool {
        return self.name == name
    }
    func containsUUID(uuid: CBUUID) -> Bool {
        return false
    }

}


