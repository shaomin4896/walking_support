//
//  websocket_io.swift
//  Siri
//
//  Created by 曾雅芳 on 2020/9/23.
//  Copyright © 2020 Sahand Edrisian. All rights reserved.
//

import UIKit
import Starscream

class websocket_io: WebSocketDelegate {
    var host = "iot.cht.com.tw"
    var apikey = "PKEE42472GRRRZ2ZAY"
    var device = "23558832518"
    var sensor = "location"
    var socket:WebSocket!
    
    init(host:String,apikey:String,device:String,sensor:String){
        self.host = host
        self.apikey = apikey
        self.device = device
        self.sensor = sensor
    }
    // MARK: - Websocket init
    func websocketInit() -> WebSocket {
        socket = WebSocket(url: URL(string: "ws://\(host):80/iot/ws/rawdata")!)
        socket.delegate = self
        self.socket.connect()
        return self.socket
    }
    // MARK: - Define WebSocket Delegate
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocketDidConnect")
        let config:NSDictionary = [
            "ck": apikey,
            "resources": ["/v1/device/\(device)/sensor/\(sensor)/rawdata"]
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: config, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        socket.write(string: jsonString!)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocketDidDisconnect", error ?? "")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("websocketDidReceiveMessage")
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("websocketDidReceiveData", data)
    }
}
