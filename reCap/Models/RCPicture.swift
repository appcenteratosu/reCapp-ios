//
//  RCPicture.swift
//  reCap
//
//  Created by App Center on 11/16/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation
import FirebaseDatabase

class RCPicture: Codable {
    var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var bearing: Double
    var orientation: Int
    var time: Int
    var owner: String
    var locationName: String
    var isRoot: Bool
    var isMostRecent: Bool
    var groupID: String
    var info: String
    
    
    init() {
        id = ""
        name = ""
        latitude = 0.0
        longitude = 0.0
        bearing = 0
        orientation = 0
        time = 0
        owner = ""
        locationName = ""
        isRoot = true
        isMostRecent = true
        groupID = ""
        info = ""
    }
    
    convenience init(snapshot: DataSnapshot) {
        self.init()
        if let data = snapshot.value as? [String: Any] {
            if let info = data["id"] as? String {
                self.id = info
            }
            if let info = data["name"] as? String {
                self.name = info
            }
            if let info = data["latitude"] as? Double {
                self.latitude = info
            }
            if let info = data["longitude"] as? Double {
                self.longitude = info
            }
            if let info = data["bearing"] as? Int {
                self.bearing = info
            }
            if let info = data["orientation"] as? Int {
                self.orientation = info
            }
            if let info = data["time"] as? Int {
                self.time = info
            }
            if let info = data["owner"] as? String {
                self.owner = info
            }
            if let info = data["locationName"] as? String {
                self.locationName = info
            }
            if let info = data["isRoot"] as? Bool {
                self.isRoot = info
            }
            if let info = data["isMostRecent"] as? Bool {
                self.isMostRecent = info
            }
            if let info = data["groupID"] as? String {
                self.groupID = info
            }
            if let info = data["info"] as? String {
                self.info = info
            }
        }
    }
    
}
