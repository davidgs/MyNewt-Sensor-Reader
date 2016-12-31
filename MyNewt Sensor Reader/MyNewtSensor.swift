/*
*  MyNewtSensor.swift
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


import Foundation
import CoreBluetooth

class MyNewtSensor : NSObject{
    var sensorLabel : String
    var nUUID : String
    var dUUID : String
    var sensorValue : Double
    
    override init() {
        sensorLabel = "Sensor"
        nUUID = "DEEE"
        dUUID = "BEEE"
        sensorValue = 0.00
        super.init()
    }
    
    init(sensorName : String, nUUID : String, dUUID : String, sensorValue : Double) {
        self.sensorLabel = sensorName
        self.nUUID = nUUID
        self.dUUID = dUUID
        self.sensorValue = sensorValue
        super.init()
    }
    
    func containsValue(value: String) -> Bool {
        return self.sensorLabel == value || self.nUUID == value || self.dUUID == value
    }
    
    func updateValue(key: String, value: Data){
        
        switch key {
        case "dUUID" :
            self.sensorValue = MyNewtDev.getAmbientTemperature(value: value as NSData)
        case "nUUID" :
            self.sensorLabel = String(bytes: value, encoding: String.Encoding.utf8)!
        default:
            return
        }
        
    }

}
