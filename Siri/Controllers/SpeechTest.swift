//
//  ViewController.swift
//  Siri
//
//  Created by Sahand Edrisian on 7/14/16.
//  Copyright © 2016 Sahand Edrisian. All rights reserved.
//

import UIKit
import Speech
import Firebase
import SocketIO
import CoreLocation


var talks : String = ""
var lati:String?
var long:String?


class SpeechTest: UIViewController, SFSpeechRecognizerDelegate {
	
    @IBOutlet weak var textView: UITextView!
	@IBOutlet weak var microphoneButton: UIButton!
	// 識別中文 英文en-US
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh_TW"))!
    // 識別請求
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    // 識別任務
    private var recognitionTask: SFSpeechRecognitionTask?
    // 聲音輸入引擎
    private let audioEngine = AVAudioEngine()
    var db: Firestore!
    let locationManager = CLLocationManager()
//    let manager = SocketManager(socketURL: URL(string: "http://192.168.100.8:8000")!, config: [.log(true), .compress])
//    var socket:SocketIOClient!

	override func viewDidLoad() {
        super.viewDidLoad()
//        self.socket = manager.defaultSocket
//        self.socket.connect()
//        self.socket.on("dangerous"){data ,ack in
//
//        }
        
        db = Firestore.firestore()
        // 麥克風按鈕是否可點,取決於使用者許可權
        microphoneButton.isEnabled = false
        // 麥克風委任
        speechRecognizer.delegate = self
        // 語音識別許可權請求
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            //button一開始關閉
            var isButtonEnabled = false
            //檢測授權
            switch authStatus {
            //如果有給授權 button開啟
            case .authorized:
                isButtonEnabled = true
            //如果沒給授權以下情形都是關閉（防呆）
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            @unknown default:
                print("fetal error")
            }
            //把檢測完授權的bool值回傳給button
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
        updatelocation()
	}
    func Tapped() -> Void {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
            print(talks)
            addnewdata()

        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    //判斷裝置是否有在錄音 如果否則進else 是則停止當前錄音
	@IBAction func microphoneTapped(_ sender: AnyObject) {
        Tapped()
	}
    //基本增刪查改
    func addnewdata(){
        let data = ["talkkkkkk": "\(talks)"]
        db.collection("speakkkkk").document("fuckkkkkk").setData(data) { (error) in
           if let error = error {
              print(error)
           }else{
            print("Document added with ID:")
            }
        }
    }
    func CreateDocuments() {
        var ref: DocumentReference? = nil
        ref = db.collection("users").addDocument(data: [
            "first": "Ada",
            "last": "Lovelace",
            "born": 1815
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    func getDocuments(){
        db.collection("users").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
    func updateDocument(id:String,born:integer_t) {
        // [START update_document]
        let ref = db.collection("users").document(id)

        // Set the "capital" field of the city 'DC'
        ref.updateData([
            "born": born
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func deleteDocument(id:String) {
        db.collection("users").document(id).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    @objc func didFinishTalk()->Void{
//        print("8787")
    }
    //按下開始扭時做的事情
    func startRecording() {
        //檢查Task事件運行狀態 如果正在運行 則取消 開始新的任務
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        // 如出錯時輸出catch
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            //設置 record=錄音
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            //如上述有錯就輸出catch
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        //初始化識別請求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        //你的錄音設備
        let inputNode = audioEngine.inputNode  //4
        //檢查 他是否初始化成功 如果沒成功 跑錯誤訊息
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        //用戶說話時將結果分批回傳打開 默認為true
        recognitionRequest.shouldReportPartialResults = true  //6
        //開始識別
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            
            //定義一個布林值 用於識別識別結束 0=識別完畢
            var isFinal = false  //8
            //  是否檢測完畢
//            var timerDidFinishTalk = Timer.scheduledTimer(timeInterval: TimeInterval(2), target: self, selector:#selector(self.didFinishTalk), userInfo: nil, repeats: false)
            
            if result != nil {
                //檢測是否識別完畢 如果識別完畢 isFinal=true
                self.textView.text = result?.bestTranscription.formattedString  //9
                talks = String((result?.bestTranscription.formattedString)!)
                if talks.count > 3{
                    let word = String(talks.suffix(4))//
                    switch word {
                    case "偵測啟動":
                        self.tabBarController?.selectedIndex = 3
                        break
                    case "註冊帳戶":
                        self.tabBarController?.selectedIndex = 2
                        break
                    case "監控位置":
                        self.tabBarController?.selectedIndex = 1
                    default:
                        break
                    }
                }
                
//                timerDidFinishTalk.invalidate()
//                timerDidFinishTalk = Timer.scheduledTimer(timeInterval: TimeInterval(2), target: self, selector:#selector(self.didFinishTalk), userInfo: nil, repeats: false)
                isFinal = (result?.isFinal)!
            }
            //如果沒有發生錯誤或以檢測完畢
            if error != nil || isFinal {  //10
                //停止錄音
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                //終止 同時讓按鈕可以用
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.microphoneButton.isEnabled = true
            }
        })
        //加入音頻輸入
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        //啟動你的裝置
        audioEngine.prepare()  //12
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        textView.text = "Say something, I'm listening!"
    }
    //當語音識別不可用時 button狀態的改變
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
}

extension SpeechTest:CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
              let currentLocation: CLLocation = locations[0] as CLLocation
              let positionPlace = String(currentLocation.coordinate.latitude) + "     " +  String(currentLocation.coordinate.longitude)
              print("現在的位置",positionPlace)
           lati = String(currentLocation.coordinate.latitude)
           long = String(currentLocation.coordinate.longitude)
           
       }
       func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
              print(error)
       }
       func updatelocation(){
           locationManager.delegate = self  //宣告自己 (current VC)為 locationManager 的代理
           locationManager.desiredAccuracy = kCLLocationAccuracyBest //定位所在地的精確程度(一般來說，精準程度越高，定位時間越長，所耗費的電力也因此更多)
           //to ask the user for location
           locationManager.requestWhenInUseAuthorization()
           //for not destroying the user's battery
           locationManager.startUpdatingLocation()
           //this method will start navigating the location. And once this is done, it will send a msg to this ViewController
       }
}
