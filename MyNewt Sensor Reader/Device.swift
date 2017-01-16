/*
*  Devices.swift
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

class Device: NSObject, TreeNode {

    let name : String
    let serviceID: String!
    let serviceUUID : CBUUID
    var serviceNo = 1
    var peripheral : CBPeripheral!
    var serviceStore = [Service]()
    
    init(name: String, id: String){
        self.name = name
        self.serviceID = id
        self.serviceUUID = CBUUID(string: id)
    }
    
    var isLeaf:Bool {
        return serviceStore.isEmpty
    }
    var childCount:Int {
        return serviceStore.count
    }
    var children:[TreeNode] {
        return serviceStore
    }
    func containsName(name: String) -> Bool {
        return self.name == name
    }
    
    func containsUUID(uuid: CBUUID) -> Bool {
        return self.serviceUUID == uuid
    }
    
    func addService(serviceName: String, serviceID: String){
        let serv = "\(serviceName) # \(serviceNo)"
        serviceStore.append(Service(name: serv, id: serviceID))
        serviceNo += 1
    }
    
    func containsService(service: String) -> Bool {
        for i in 0..<serviceStore.count {
            if(serviceStore[i].containsName(name: service)){
                return true
            }
        }
        return false
        
    }
    
    
}
