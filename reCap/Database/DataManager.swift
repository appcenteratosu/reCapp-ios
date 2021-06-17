//
//  DataManager.swift
//  reCap
//
//  Created by App Center on 11/12/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation

import Firebase

class DataManager {
    static var currentFBUser: User!
    static var currentAppUser: ChallengeSetup!
//        didSet {
//            var pictures: [String] = []
//
//            for pic in currentAppUser.pictures {
//                pictures.append(pic.id)
//            }
//
//            var friends: [String] = []
//            currentAppUser.friends.forEach { (user) in
//                friends.append(user.id)
//            }
//
//            let values: [String: Any] = ["id": currentFBUser.uid,
//                        "name": currentAppUser.name,
//                        "points": currentAppUser.points,
//                        "pictures": pictures,
//                        "email": currentAppUser.email,
//                        "friends": friends,
//                        "activeChallenge": currentAppUser.activeChallenge?.id,
//                        "activeChallengePoints": currentAppUser.activeChallengePoints,
//                        "state": currentAppUser.state,
//                        "country": currentAppUser.country,
//                        "longitude": currentAppUser.longitude,
//                        "latitude": currentAppUser.latitude]
//
//            FirebaseHandler.database.child("UserData").child(currentFBUser.uid).setValue(values)
//        }
    
    
}
