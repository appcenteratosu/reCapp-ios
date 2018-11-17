//
//  RCUser.swift
//  reCap
//
//  Created by App Center on 11/16/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation
import FirebaseDatabase

class RCUser: Codable {
    var id: String
    var name: String
    var points: Int
    var email: String
    var friends: [String]
    var activeChallenge: String
    var activeChalengePoints: Int
    var state: String
    var country: String
    var latitude: Double
    var longitude: Double
    var pictures: [String]
    
    init() {
        id = ""
        name = ""
        points = 0
        email = ""
        friends = []
        activeChallenge = ""
        activeChalengePoints = 0
        state = ""
        country = ""
        latitude = 0.0
        longitude = 0.0
        pictures = []
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
            if let info = data["points"] as? Int {
                self.points = info
            }
            if let info = data["email"] as? String {
                self.email = info
            }
            if let info = data["friends"] as? [String: Any] {
                for item in info {
                    let friend = item.key
                    self.friends.append(friend)
                }
            }
            if let info = data["activeChallenge"] as? String {
                self.activeChallenge = info
            }
            if let info = data["activeChalengePoints"] as? Int {
                self.activeChalengePoints = info
            }
            if let info = data["state"] as? String {
                self.state = info
            }
            if let info = data["country"] as? String {
                self.country = info
            }
            if let info = data["latitude"] as? Double {
                self.latitude = info
            }
            if let info = data["longitude"] as? Double {
                self.longitude = info
            }
            if let info = data["pictures"] as? [String: Any] {
                for item in info {
                    let pictureID = item.key
                    self.pictures.append(pictureID)
                }
            }
        }
    }
    
    func getActiveChallenge(completion: @escaping (RCPicture?)->()) {
        FirebaseHandler.database.child("PictureData").child(activeChallenge).observeSingleEvent(of: .value) { (snap) in
            if snap != nil {
                let pic = RCPicture(snapshot: snap)
                completion(pic)
            } else {
                completion(nil)
            }
        }
    }
    
    func getBearingForActiveChallenge(completion: @escaping (_ bearing: Double?)->()) {
        FirebaseHandler.database.child("PictureData").child(activeChallenge).observeSingleEvent(of: .value) { (snap) in
            if snap != nil {
                let pic = RCPicture(snapshot: snap)
                completion(pic.bearing)
            } else {
                completion(nil)
            }
        }
    }
    
}

