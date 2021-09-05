//
//  FaceAuthIO.swift
//  Siri
//
//  Created by Sam on 2020/11/18.
//  Copyright © 2020 Sahand Edrisian. All rights reserved.
//

import UIKit
import Firebase
import Foundation

class FaceAuthIO: NSObject {
    var xapi_key:String
    var groupID:String
    var url:String
    var headParameter:[String:String]
    init(api_key:String,groupid:String) {
        self.xapi_key = api_key
        self.groupID = groupid
        self.headParameter = ["X-API-KEY":api_key,"Accept":"application/json"]
        self.url = "https://iot.cht.com.tw/apis/CHTIoT/face/v2/FaceGroup/"
    }
    
    
    func authFace(base64imageStr:String,completion:@escaping (String,Double)->()) -> Void {
        
        let semaphore = DispatchSemaphore (value: 0)
        
        let parameters = "{\n  \"queryData\": \"\(base64imageStr)\",\n  \"topK\": 3\n}"
        let postData = parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "https://iot.cht.com.tw/apis/CHTIoT/face/v2/FaceGroup/FG202012020510258562949594/Match")!,timeoutInterval: Double.infinity)
        request.addValue("884e4a98-9ac9-45bb-9d41-3dba52f9e4f1", forHTTPHeaderField: "X-API-KEY")
        request.addValue("text/plain", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
            if let matchResult = json?["matchResults"] as? [Any]{
                if let match = matchResult[0] as? [String:Any] {
                    if let condidates = match["candidates"] as? [[String:Any]]{
                        if let condidate = condidates[0] as? [String:Any]{
                            completion((condidate["groupedFaceId"] as? String)!,(condidate["score"] as? Double)!)
                        }
                    }
                }
            }
            
//            if let matchResult = json!["matchResults"] as?[String:Any]{
//                if let condidates = matchResult["candidates"] as? [[String:String]]{
//                    print(condidates)
//                }
//            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
    }
    
    func newFace(base64imageStr:String,nickname:String,completion:@escaping(String)->()) -> Void {
        
        let semaphore = DispatchSemaphore (value: 0)

        let parameters = "{\n  \"imgData\": \"\(base64imageStr)\",\n  \"faceMetadata\": \"\(nickname)\"\n}"
        let postData = parameters.data(using: .utf8)

        var request = URLRequest(url: URL(string: "https://iot.cht.com.tw/apis/CHTIoT/face/v2/FaceGroup/FG202012020510258562949594")!,timeoutInterval: Double.infinity)
        request.addValue("884e4a98-9ac9-45bb-9d41-3dba52f9e4f1", forHTTPHeaderField: "X-API-KEY")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
            if let FaceID = json?["groupedFaceId"] as? String{
                completion(FaceID)
            }
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

    }
}
// MARK: - DetectRespone
struct DetectRespone: Codable {
    let matchResults: [MatchResult]
    let code: Int
    let message: String
}

// MARK: - MatchResult
struct MatchResult: Codable {
    let queryFaceRect: QueryFaceRect
    let candidates: [Candidate]
}

// MARK: - Candidate
struct Candidate: Codable {
    let score: Double
    let groupedFaceID: String

    enum CodingKeys: String, CodingKey {
        case score
        case groupedFaceID = "groupedFaceId"
    }
}

// MARK: - QueryFaceRect
struct QueryFaceRect: Codable {
    let queryFaceRectRight, bottom, queryFaceRectLeft, top: Int

    enum CodingKeys: String, CodingKey {
        case queryFaceRectRight = "right"
        case bottom
        case queryFaceRectLeft = "left"
        case top
    }
}
