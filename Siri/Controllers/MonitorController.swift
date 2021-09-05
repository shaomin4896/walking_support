//
//  MonitorController.swift
//  Siri
//
//  Created by 曾雅芳 on 2020/9/21.
//  Copyright © 2020 Sahand Edrisian. All rights reserved.
//

import UIKit
import MapKit
import JJFloatingActionButton
import CoreLocation
import Starscream


class MonitorController: UIViewController, MKMapViewDelegate{
    // MARK: - Components Define
    var myMapView:MKMapView!
    var targetAnno:MKPointAnnotation!
    var locationManager: CLLocationManager!
    
    // MARK: - Connection Tool Define
    var mqtt:mqtt_io!
    var socket:WebSocket!
    var websocketio:websocket_io!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addMapComponents()
        addFloatingButtonComponents()
        mqttInit()
        WebScocketInit()
        locationMangagerInit()
    }
    // MARK: - MQTT
    func mqttInit() -> Void {
        mqtt = mqtt_io(
        host: "iot.cht.com.tw",
        apikey: "PKZ2KMXX57F71H14Z0",
        device: "25068501076")
    }
    func locationMangagerInit() -> Void {
        self.locationManager = CLLocationManager()
        self.locationManager?.allowsBackgroundLocationUpdates = true // 開啟背景更新(預設為 false)
        self.locationManager?.pausesLocationUpdatesAutomatically = false // 不間斷的在背景更新(預設為 true)
        self.locationManager?.requestAlwaysAuthorization() // 詢問使用者是否在背景也可取用其位置的隱私
        self.locationManager?.delegate = self
    }
    // MARK: - WebSocket
    func WebScocketInit() -> Void {
        websocketio = websocket_io(
            host: "iot.cht.com.tw",
            apikey: "PKZ2KMXX57F71H14Z0",
            device: "25068501076",
            sensor: "location")
        socket = websocketio.websocketInit()
        socket.onText = { text in
            self.targetAnno.subtitle = text
            let messageData = text.data(using: .utf8)
            let result = try? JSONDecoder().decode(Location.self, from: messageData!)
            if let locationStr=result?.value[0]{
                let location = locationStr.split(separator: ",")
                let lat = Double(location[0])
                let lon = Double(location[1])
                self.updateAnnoLocation(lati: lat!, long: lon!)
            }
        }
    }
    // MARK: - Map init
    func addMapComponents() -> Void{
        let fullSize = UIScreen.main.bounds.size

        // 建立一個 MKMapView
        myMapView = MKMapView(frame: CGRect(
          x: 0, y: 0,
          width: fullSize.width,
          height: fullSize.height - 20))

        // 設置委任對象
        myMapView.delegate = self

        // 地圖樣式
        myMapView.mapType = .standard

        // 顯示自身定位位置
        myMapView.showsUserLocation = true

        // 允許縮放地圖
        myMapView.isZoomEnabled = true
        
        myMapView.showsTraffic = true
        // 地圖預設顯示的範圍大小 (數字越小越精確)
        let latDelta = 0.05
        let longDelta = 0.05
        let currentLocationSpan:MKCoordinateSpan =
            MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)

        // 設置地圖顯示的範圍與中心點座標
        let center:CLLocation = CLLocation(
          latitude: 25.05, longitude: 121.515)
        let currentRegion:MKCoordinateRegion =
          MKCoordinateRegion(
            center: center.coordinate,
            span: currentLocationSpan)
        myMapView.setRegion(currentRegion, animated: true)

        // 加入到畫面中
        self.view.addSubview(myMapView)
        
        // init Target anno
        targetAnno = MKPointAnnotation()
        myMapView.addAnnotation(targetAnno)
        updateAnnoLocation(lati: 25.063059, long: 121.533838)
    }
    func updateAnnoLocation(lati:Double,long:Double)->Void{
        targetAnno.coordinate = CLLocationCoordinate2D(latitude: lati, longitude: long)
        targetAnno.title = "\(targetAnno.coordinate.latitude)\n\(targetAnno.coordinate.longitude)"
    }
    // MARK: - Floating Button
    func addFloatingButtonComponents() -> Void {
        
        let actionButton = JJFloatingActionButton()

        actionButton.addItem(title: "RandomMove", image: UIImage(systemName: "arrow.clockwise")?.withRenderingMode(.alwaysTemplate)) { item in
            self.updateAnnoLocation(lati: self.targetAnno.coordinate.latitude+0.01, long: self.targetAnno.coordinate.longitude+0.01)
            self.mqtt.publish(sensor: "location", value:"\(self.targetAnno.coordinate.latitude),\(self.targetAnno.coordinate.longitude)")
        }

        actionButton.addItem(title: "Tracking", image: UIImage(systemName: "arrow.swap")?.withRenderingMode(.alwaysTemplate)) { item in
            
        }
        
        var count = 0
        actionButton.addItem(title: "Move By Step", image: UIImage(systemName: "arrow.right.to.line.alt")?.withRenderingMode(.alwaysTemplate)){ item in
            self.mqtt.publish(sensor: "location", value:"\(count)")
            count+=1
        }
        
        actionButton.display(inViewController: self)
    }
}
// MARK: - CLLocationManagerDelegate
extension MonitorController: CLLocationManagerDelegate {
    
    /// 更新位置
    ///
    /// - Parameters:
    ///   - manager: _
    ///   - locations: _
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("didUpdateLocations: \(locations.first!)")
    }
}
