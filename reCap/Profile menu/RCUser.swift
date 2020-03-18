//
//  RCUser.swift
//  reCap
//
//  Created by App Center on 11/16/18.
//  Copyright © 2020 OSU App Center. All rights reserved.
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
    
    var activeChallengeObj: RCPicture? = nil
    
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
            
            if let id = snapshot.key as? String {
                self.id = id
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
        if !activeChallenge.isEmpty {
            FirebaseHandler.database.child("PictureData").child(activeChallenge).observeSingleEvent(of: .value) { (snap) in
                
                let pic = RCPicture(snapshot: snap)
                self.activeChallengeObj = pic
                self.activeChallenge = pic.id
                completion(pic)
                
            }
        } else {
            completion(nil)
        }
    }
    
    func getActiveChallenge(updated: Bool, completion:  @escaping (RCPicture?)->()) {
        if updated { // Updated in Firebase, so get the new object
            FirebaseHandler.database.child("UserData").child(self.id).child("activeChallenge").observeSingleEvent(of: .value) { (snap) in
                if let challengeID = snap.value as? String {
                    if challengeID.isEmpty {
                        // Empty String, no challenge
                        completion(nil)
                    } else {
                        FirebaseHandler.database.child("PictureData").child(self.activeChallenge).observeSingleEvent(of: .value) { (snap) in
                            let pic = RCPicture(snapshot: snap)
                            self.activeChallengeObj = pic
                            self.activeChallenge = pic.id
                            completion(pic)
                        }
                    }
                } else {
                    Log.e("Could not get challenge id from snap as String")
                }
            }
        } else {
            if let challenge = self.activeChallengeObj {
                // Object already Exists
                completion(challenge)
            } else {
                FirebaseHandler.database.child("UserData").child(self.id).child("activeChallenge").observeSingleEvent(of: .value) { (snap) in
                    if let challengeID = snap.value as? String {
                        if challengeID.isEmpty {
                            // Empty String, no challenge
                            completion(nil)
                        } else {
                            FirebaseHandler.database.child("PictureData").child(self.activeChallenge).observeSingleEvent(of: .value) { (snap) in
                                let pic = RCPicture(snapshot: snap)
                                self.activeChallengeObj = pic
                                self.activeChallenge = pic.id
                                completion(pic)
                            }
                        }
                    } else {
                        Log.e("Could not get challenge id from snap as String")
                    }
                }
            }
        }
    }
    
    func getBearingForActiveChallenge(completion: @escaping (_ bearing: Double?)->()) {
        if let challenge = self.activeChallengeObj {
            completion(challenge.bearing)
        }
    }
    
    func update(values: [Properties: Any]) {
        var data: [String: Any] = [:]
        for item in values {
            switch item.key {
            case .points:
                data["points"] = item.value
                points = item.value as! Int
            case .activeChallenge:
                data["activeChallenge"] = item.value
                activeChallenge = item.value as! String
            case .activeChallengePoints:
                data["activeChallengePoints"] = item.value
                activeChalengePoints = item.value as! Int
            case .state:
                data["state"] = item.value
                state = item.value as! String
            case .country:
                data["country"] = item.value
                country = item.value as! String
            case .latitude:
                data["latitude"] = item.value
                latitude = item.value as! Double
            case .longitude:
                data["longitude"] = item.value
                longitude = item.value as! Double
            case .name:
                name = item.value as! String
                data["name"] = item.value
                let req = DataManager.currentFBUser.createProfileChangeRequest()
                req.displayName = name
                req.commitChanges { (error) in
                    guard error == nil else {
                        Log.s("Name could not be changed: \(error!.localizedDescription)")
                        return
                    }
                }
            default:
                break
            }
        }
        
        FirebaseHandler.database.child("UserData").child(id).updateChildValues(data)
    }
    
    func add(friend: RCUser) {
        self.friends.append(friend.id)
        FirebaseHandler.database.child("UserData").child(id).child("friends").child(friend.id).setValue(true)
    }
    
    func remove(friend: RCUser) {
        self.friends.removeAll { (id) -> Bool in
            return id == friend.id
        }
        FirebaseHandler.database.child("UserData").child(id).child("friends").child(friend.id).setValue(nil)
    }
    
    enum Properties {
        case id
        case name
        case points
        case email
        case friends
        case activeChallenge
        case activeChallengePoints
        case state
        case country
        case latitude
        case longitude
        case pictures
    }

    
    
}
