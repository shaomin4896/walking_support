//
//  JsonProvider.swift
//  Siri
//
//  Created by 曾雅芳 on 2020/9/23.
//  Copyright © 2020 Sahand Edrisian. All rights reserved.
//

import Foundation

struct Location:Codable {
    var id:String
    var deviceId:String
    var time:String
    var value:[String]
}
