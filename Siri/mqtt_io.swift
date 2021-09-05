//
//  mqtt_io.swift
//  Siri
//
//  Created by 曾雅芳 on 2020/9/23.
//  Copyright © 2020 Sahand Edrisian. All rights reserved.
//

import UIKit
import SwiftMQTT

class mqtt_io {
    
    var host = "iot.cht.com.tw"
    var apikey = "PKEE42472GRRRZ2ZAY"
    var device = "23558832518"
    var mqtt:MQTTSession!
    
    init(host:String,apikey:String,device:String){
        self.host = host
        self.apikey = apikey
        self.device = device
        mqtt = MQTTSession(
            host: host,
            port: 1883,
            clientID: "swift", // must be unique to the client
            cleanSession: true,
            keepAlive: 60,
            useSSL: false
        )
        mqtt.username = apikey
        mqtt.password = apikey
        mqtt.connect { error in
            if error == .none {
                print("Connected!")
            } else {
                print(error.description)
            }
        }
    }
    func publish(sensor:String,value:String) -> Void {
        let payload:[NSDictionary] = [[
            "id": "\(sensor)",
            "value": ["\(value)"]
        ]]
        let data = try! JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        let topic = "/v1/device/\(device)/rawdata"

        mqtt.publish(data, in: topic, delivering: .atLeastOnce, retain: false) { error in
            if error == .none {
                print("Published data in \(topic)!")
            } else {
                print(error.description)
            }
        }
    }
}
