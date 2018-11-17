//
//  UserData.swift
//  reCap
//
//  Created by Jackson Delametter on 4/8/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation

import FirebaseDatabase

class UserData: Object {
    // MARK: - Properties
    @objc dynamic var id: String!
    @objc dynamic var name: String!
    @objc dynamic var points = 0
    @objc dynamic var email: String!
    var friends = List<String>()
    @objc dynamic var activeChallenge: String?
    @objc dynamic var activeChallengePoints = 0
    @objc dynamic var state: String!
    @objc dynamic var country: String!
    @objc dynamic var longitude = 0.0
    @objc dynamic var latitude = 0.0
    
    convenience required init(id: String, name: String, email: String) {
        self.init()
        self.id = id
        self.name = name
        self.email = email
        self.activeChallengePoints = 0
    }
    
    convenience init(snapshot: DataSnapshot) {
        self.init()
        
        if let data = snapshot.value as? [String: Any] {
            if let info = data["name"] as? String{
                self.name = info
            }
            if let info = data["points"] as? Int {
                self.points = info
            }
            if let info = data["friends"] as? String {
                self.friends.append(info)
            }
            if let info = data["activeChallenge"] as? String {
                self.activeChallenge = info
            }
            if let info = data["activeChallengePoints"] as? Int {
                self.activeChallengePoints = info
            }
            if let info = data["state"] as? String{
                self.state = info
            }
            if let info = data["country"] as? String{
                self.country = info
            }
            if let info = data["longitude"] as? Double {
                self.longitude = info
            }
            if let info = data["latitude"] as? Double {
                self.latitude = info
            }
        }
        
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["email"]
    }
}
