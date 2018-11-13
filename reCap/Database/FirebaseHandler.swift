//
//  FirebaseHandler.swift
//  reCap
//
//  Created by App Center on 11/4/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation
import Firebase

class FirebaseHandler {
    static var auth = Auth.auth()
    static var database = Database.database().reference()
    static var storage = Storage.storage().reference()
    
    private static var PictureData = "PictureData"
    private static var UserDataString = "UserData"
    private static var ProfilePictures = "ProfilePictures"
    
    public static var CurrentUserData: UserData?
    
    public static var DatabaseHandles: [DatabaseHandle] = []

    
    static func createAccount(name: String, email: String, password: String, completion: @escaping (Error?, User?)->()) {
        auth.createUser(withEmail: email, password: password) { (result, error) in
            if error != nil {
                print(error!.localizedDescription)
                completion(error!, nil)
            } else {
                if let user = result?.user {
                    completion(nil, user)
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    static func login(email: String, password: String, completion: @escaping (Error?, User?)->()) {
        auth.signIn(withEmail: email, password: password) { (result, error) in
            if error != nil {
                print(error!.localizedDescription)
                completion(error!, nil)
            } else {
                if let user = result?.user {
                    completion(nil, user)
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    static func logout(completion: ()->()) {
        do {
            try auth.signOut()
            completion()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func createUserDataReference(userData user: UserData, completion: @escaping (Error?)->()) {
        var data: [String: Any?] = ["name": user.name,
                                   "points": user.points,
                                   "pictures": nil,
                                   "friends": nil,
                                   "activeChallenge": nil,
                                   "activeChallengePoints": 0,
                                   "state": user.state,
                                   "country": user.country,
                                   "longitude": user.longitude,
                                   "latitude": user.latitude]
        
        database.child(UserDataString).child(user.id).setValue(data) { (error, ref) in
            completion(error)
        }
    }
    
    static func storeProfilePicture(image: UIImage, userID uid: String, completion: @escaping (Error?)->()) {
        let reference  = storage.child(ProfilePictures).child(uid)
        if let imageData = UIImageJPEGRepresentation(image, 0.2) {
            let task = reference.putData(imageData, metadata: nil) { (meta, error) in
                if error != nil {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    static func getProfilePicture(userID uid: String, completion: @escaping (UIImage?)->(), progress: @escaping (Double)->()) {
        let ref = storage.child(ProfilePictures).child(uid)
        let downloadTask = ref.getData(maxSize: 1 * 1024 * 1024) { (data, error) -> Void in
            if let data = data {
                if let img = UIImage(data: data) {
                    completion(img)
                }
            } else {
                completion(nil)
            }
        }
        
        downloadTask.observe(.progress) { (snap) in
            if let progressData = snap.progress {
                let current = progressData.completedUnitCount
                let total = progressData.totalUnitCount
                if total != 0 {
                    let dProgress = Double((current / total) * 100)
                    progress(dProgress)
                }
            }
        }
    }
    
    static func createPictureDataReference(pictureData: PictureData) {
        var data: [String: Any] = ["name": pictureData.name,
                    "info": pictureData.info,
                    "id": pictureData.id,
                    "latitude": pictureData.latitude,
                    "longitude": pictureData.longitude,
                    "bearing": pictureData.bearing,
                    "orientation": pictureData.orientation,
                    "owner": pictureData.owner.id,
                    "time": pictureData.time,
                    "locationName": pictureData.locationName,
                    "isRootPicture": pictureData.isRootPicture,
                    "isMoseRecentPicture": pictureData.isMostRecentPicture,
                    "groupID": pictureData.groupID]
        
        database.child(PictureData).child(pictureData.id).setValue(data) { (error, ref) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("SAVED")
            }
        }
    }
    
    static func getUserData(completion: @escaping (UserData)->()) {
        if let user = auth.currentUser {
            let handle = database.child(UserDataString).child(user.uid).observe(.value) { (snap) in
                if let data = snap.value as? [String: Any] {
                    let name = data["name"] as! String
                    let userData = UserData(id: user.uid, name: name, email: user.email!)
                    
                    if let challengePoints = data["activeUserChallengePoints"] as? Int {
                        userData.activeChallengePoints = challengePoints
                    }
                    
                    if let lat = data["latitude"] as? Double {
                        userData.latitude = lat
                    }
                    
                    if let lon = data["longitude"] as? Double {
                        userData.longitude = lon
                    }
                    
                    if let points = data["points"] as? Int {
                        userData.points = points
                    }
                    DataManager.currentAppUser = userData
                    CurrentUserData = userData
                    completion(userData)
                }
            }
            
            DatabaseHandles.append(handle)
            
        }
    }
    
    static func updateUserLocation(lat: Double, lon: Double) {
        database.child(UserDataString).child(DataManager.currentFBUser.uid).child("latitude").setValue(lat)
        database.child(UserDataString).child(DataManager.currentFBUser.uid).child("longitude").setValue(lon)
    }
    
    
}
