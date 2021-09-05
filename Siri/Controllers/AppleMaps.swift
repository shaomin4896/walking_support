//
//  AppleMaps.swift
//  Siri
//
//  Created by Hung-Ming Chen on 2020/3/26.
//  Copyright © 2020 Sahand Edrisian. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import UserNotifications
import AVFoundation
extension Date {
    func toString(format: String) -> String {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = format
        
        return dateFormat.string(from: self)
    }
}
class AppleMaps: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate,UISearchBarDelegate {
    var myLocationMgr :CLLocationManager!
    var myMapView :MKMapView!
    var FB: Firestore!
    var positionPlace: String = ""
    var xpoint : Double?
    var ypoint : Double?
    var userLocation : CLLocationCoordinate2D!
    var latt:Double?
    var lont:Double?
    var position:String?
    var placemarkk:String?
    var sbar:String?
    var latitudePoint:Double?
    var longitudePoint:Double?
    var searchstartplace:String?
    var searchendplace:String?
    
    let synth = AVSpeechSynthesizer()
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FB = Firestore.firestore()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create location data
        myLocationMgr = CLLocationManager()
        myLocationMgr.delegate = self
        
        // update data
        myLocationMgr.distanceFilter = kCLLocationAccuracyHundredMeters
        myLocationMgr.desiredAccuracy = kCLLocationAccuracyBest
        
        // Create MapView
        let screenSize = UIScreen.main.bounds
        myMapView = MKMapView(frame: CGRect(x: 0,
                                            y: 20,
                                            width: screenSize.width,
                                            height: screenSize.height - 20))
        myMapView.delegate = self
        myMapView.mapType = .standard
        myMapView.showsUserLocation = true
        myMapView.isZoomEnabled = true // allow zoom in(out)
        self.view.addSubview(myMapView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 取得權限防呆
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            myLocationMgr.requestWhenInUseAuthorization() // 首次啟動取得用戶權限
            fallthrough
        case .authorizedWhenInUse:
            myLocationMgr.startUpdatingLocation() // 開始更新位置
            
        case .denied:
            let alertController = UIAlertController(title: "定位權限已關閉",
                                                    message:"如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default, handler:nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
        default:
            break
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 停止更新位置
        myLocationMgr.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func navagationVoice(){
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] (timer) in
            
            guard let weakSelf = self else {
                return
            }
        
            let text = "現在時刻：" + Date().toString(format: "HH:mm")
//                weakSelf.textView.text = text
            
            let myUtterance = AVSpeechUtterance(string: text)
            myUtterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
            myUtterance.rate = 0.5    
            weakSelf.synth.speak(myUtterance)
        }
        
        timer.fire()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation: CLLocation = locations[0] as CLLocation
        positionPlace = String(currentLocation.coordinate.latitude) + "     " +  String(currentLocation.coordinate.longitude)
        print("現在的位置",positionPlace)
        createdata()
        
        userLocation = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
        
        latitudePoint = currentLocation.coordinate.latitude
        longitudePoint = currentLocation.coordinate.longitude
        print("userLocation",userLocation.latitude,userLocation.longitude)
        
        let center = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude,
                                            longitude: currentLocation.coordinate.longitude)
        
        // paramater span means the range of map
        let region = MKCoordinateRegion(center: center,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        myMapView.setRegion(region, animated: true)
        //導航
        if latt != nil  {
            //將目標經緯度放進pendCoor
            let pendCoor = CLLocationCoordinate2D(latitude: latt!, longitude: lont!)
            let pointstart = MKPlacemark(coordinate: userLocation)
            let pointend = MKPlacemark(coordinate: pendCoor)
            let start = MKMapItem(placemark: pointstart)
            let end = MKMapItem(placemark: pointend)
            start.name = "您的位置"
            end.name = sbar
            //起始大頭針
            self.geocode(latitude: latitudePoint!, longitude: longitudePoint!){ placemark,error in
                guard let placemark = placemark, error == nil else {return}
                    if placemark != nil{
                        let place = placemark as CLPlacemark
                        print (place)
                        let address: NSString = ((placemark.addressDictionary! as NSDictionary).value(forKey: "FormattedAddressLines") as AnyObject).firstObject as! NSString
                        self.searchstartplace = String(address)
                        print ("起點", self.latitudePoint! , self.longitudePoint!)
                        //移除大頭針
                        let annotations = self.myMapView.annotations
                        self.myMapView.removeAnnotations(annotations)
                        //起始大頭針
                        let firstannotation = MKPointAnnotation()
                        if let loca = pointstart.location{
                            firstannotation.coordinate = loca.coordinate
                        }
                        firstannotation.title = place.name
                        firstannotation.subtitle = self.searchstartplace
                    self.myMapView.showAnnotations([firstannotation], animated: true)
                }
            }
            //計算路線
            let directionRequest = MKDirections.Request()
            directionRequest.source = start
            directionRequest.destination = end
            directionRequest.transportType = .walking
            let directions = MKDirections(request: directionRequest)
            directions.calculate { (response, error) in
                if error != nil{
                    print("無此路線")
                }else{
                    self.showRoute(response!)
                }
//                guard let response = response else {
//                    if let error = error{
//                        print ("路線 \(error)")
//                    }
//                    return
//                }

//                let route = response.routes[0]
//                self.myMapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
//                let rect = route.polyline.boundingMapRect
//                self.myMapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
    }
    func showRoute (_ response: MKDirections.Response){
        for route in response.routes {
            myMapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            for step in route.steps{
                print(step.instructions)
            }
        }
    }
    func mapView(_ mapView: MKMapView, rendererFor
        overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer =  MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        renderer.lineWidth = 5.0
        return renderer
    }
    @IBAction func searchButton(_ sender: Any) {
        //創造一個searchbar
        let searchcontroller = UISearchController(searchResultsController: nil)
        searchcontroller.searchBar.delegate = self
        present(searchcontroller, animated: true, completion: nil)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //忽略觸摸相關事件
        UIApplication.shared.beginIgnoringInteractionEvents()
        //顯示正在執行的畫面
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        
        //隱藏搜尋盤
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        //搜尋請求
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activitySearch = MKLocalSearch(request: searchRequest)
        sbar = searchBar.text
        activitySearch.start { (response, error) in
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            self.latt = response?.boundingRegion.center.latitude
            self.lont = response?.boundingRegion.center.longitude
            if response == nil{
                print("response error")
            }else{
                self.geocode(latitude: self.latt!, longitude: self.lont!){ placemark,error in
                guard let placemark = placemark, error == nil else {return}
                    if placemark != nil{
                        let place = placemark as CLPlacemark
                        print (place)
                        self.placemarkk = place.name
                        let address: NSString = ((placemark.addressDictionary! as NSDictionary).value(forKey: "FormattedAddressLines") as AnyObject).firstObject as! NSString
                        self.searchendplace = String(address)
                        print("地址", address)
                        print ("目的", self.latt! , self.lont!)
                        //移除大頭針
//                        let annotations = self.myMapView.annotations
//                        self.myMapView.removeAnnotations(annotations)
                        //取得經緯度
                        let lat = response?.boundingRegion.center.latitude
                        let lon = response?.boundingRegion.center.longitude
                        //Create 大頭針
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = CLLocationCoordinate2DMake(lat!, lon!)
                        
                        annotation.title = self.placemarkk
                        annotation.subtitle = self.searchendplace
                        self.myMapView.addAnnotation(annotation)
                        self.myMapView.showAnnotations([annotation], animated: true)
                        self.myMapView.selectAnnotation(annotation, animated: true)
                        //大頭針資訊
                        let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat! , lon!)
                        let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: span.latitudeDelta, longitudinalMeters: span.longitudeDelta)
                        self.myMapView.setRegion(region, animated: true)
                    }
                }
            }
        }
    }
      //設定檢索語言
    func geocode(latitude: Double, longitude: Double, completion: @escaping (CLPlacemark?, Error?) -> ())  {
        let locale = Locale(identifier: "zh_TW")
        let loc: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        if #available(iOS 11.0, *){
            CLGeocoder().reverseGeocodeLocation(loc, preferredLocale: locale){ placemarks,error in
                guard let placemark = placemarks?.first, error == nil else {
                    UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                    completion(nil , error)
                    return
                }
                completion(placemark, nil)
            }
        }
    }
    func firstLocationData (){
        geocode(latitude: latitudePoint!, longitude: longitudePoint!){ placemark,error in
            guard let placemark = placemark, error == nil else {return}
            DispatchQueue.main.async {
                if placemark != nil{
                    let place = placemark as CLPlacemark
                    print (place)
                    self.searchstartplace = place.name
                    print ("起點", self.latitudePoint! , self.longitudePoint!)
                }
            }
        }
    }
//    private func myMapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
//        let renderer = MKPolylineRenderer(overlay: overlay)
//        renderer.strokeColor = UIColor.red
//        renderer.lineWidth = 4.0
//
//        return renderer
//
//    }
    func getmapdirections(){
        
    }
    func createdata(){
        let data = ["locat": "\(positionPlace)"]
        FB.collection("location").document("loca").setData(data) { (error) in
            if let error = error {
                print(error)
            }else{
                print("")
            }
        }
    }
}
