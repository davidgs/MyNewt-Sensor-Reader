/*
 *  Service.swift
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

class Service: NSObject, TreeNode {

    let name: String
    let serviceID : String
    let serviceUUID : CBUUID
    
    init(name: String, id : String){
        self.name = name
        self.serviceID = id
        self.serviceUUID = CBUUID(string: id)
    }
    var isLeaf:Bool {
        return true
    }
    var childCount:Int {
        return 0
    }
    var children:[TreeNode] {
        return []
    }
    
    func containsName(name: String) -> Bool {
        return self.name == name
    }
    
    func containsUUID(uuid: CBUUID) -> Bool {
        return self.serviceUUID == uuid
    }
}
@objc protocol TreeNode:class {
    var isLeaf:Bool { get }
    var childCount:Int { get }
    var children:[TreeNode] { get }
    func containsName(name: String) -> Bool
    func containsUUID(uuid: CBUUID) -> Bool
}
