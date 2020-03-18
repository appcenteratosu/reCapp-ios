//
//  FirebaseHandler.swift
//  reCap
//
//  Created by App Center on 11/4/18.
//  Copyright © 2020 OSU App Center. All rights reserved.
//

import Foundation
import Firebase
import FCAlertView

class FirebaseHandler {
    static var auth = Auth.auth()
    static var database = Database.database().reference()
    static var storage = Storage.storage().reference()
    
    private static var PictureData = "PictureData"
    private static var UserDataString = "UserData"
    private static var ProfilePictures = "ProfilePictures"
    
    public static var CurrentUserData: RCUser?
    
    public static var DatabaseHandles: [DatabaseHandle] = []

    static func findAccount(for email: String, completion: @escaping (RCUser?, Bool?)->()) {
        let ref = database.child(UserDataString)
        let query = ref.queryOrdered(byChild: "email").queryEqual(toValue: email)
        query.observeSingleEvent(of: .value) { (snapshot) in
            guard let data = snapshot.children.allObjects as? [DataSnapshot] else {
                completion(nil, false)
                return
            }
            for item in data {
                let user = RCUser(snapshot: item)
                if user.email == email {
                    completion(user, true)
                } else {
                    completion(nil, false)
                }
            }
            
        }
    }
    
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
    
    static func createUserDataReference(userData user: RCUser, completion: @escaping (Error?)->()) {
        var data: [String: Any?] = ["name": user.name,
                                    "email": user.email,
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
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            let task = reference.putData(imageData, metadata: nil) { (meta, error) in
                if error != nil {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    static func storeImage(image: UIImage, picture: RCPicture, view: UIViewController, whenDone: @escaping ()->()) {
        FCAlertView.showProgressAlert(title: "Uploading Image", message: "Please Wait", view: view, blur: true, completion: { (alert) in
            let ref = storage.child("Pictures").child(picture.id)
            if let data = image.jpegData(compressionQuality: 1.0) {
                let task = ref.putData(data, metadata: nil) { (meta, error) in
                    alert.dismiss()
                    if error != nil {
                        Log.e(error!.localizedDescription)
                    } else {
                        Log.i("No error")
                        whenDone()
                    }
                }
            }
        })
    }
    
    static func deleteImage(picture: RCPicture) {
        let storageRef = storage.child("Pictures").child(picture.id)
        let databaseRef = database.child("PictureData").child(picture.id)
        
        databaseRef.setValue(nil)
        Log.i("Delete photo data from database")
        
        storageRef.delete { (error) in
            guard error == nil else {
                Log.e(error!.localizedDescription)
                return
            }
            Log.i("Deleted photo from storage")
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
    
    static func createPictureDataReference(pictureData: RCPicture, completion: @escaping (RCPicture?)->()) {
        guard let id = database.child("PictureData").childByAutoId().key else { return }
        let picture = pictureData
        picture.id = id
        var data: [String: Any] = ["name": pictureData.name,
                    "info": pictureData.info,
                    "id": id,
                    "latitude": pictureData.latitude,
                    "longitude": pictureData.longitude,
                    "bearing": pictureData.bearing,
                    "orientation": pictureData.orientation,
                    "owner": pictureData.owner,
                    "time": pictureData.time,
                    "locationName": pictureData.locationName,
                    "isRootPicture": pictureData.isRoot,
                    "isMostRecentPicture": pictureData.isMostRecent]
        
        if pictureData.isRoot {
            data["groupID"] = id
            picture.groupID = id
        } else {
            data["groupID"] = pictureData.groupID
            picture.groupID = pictureData.groupID
        }
        
        database.child(PictureData).child(id).setValue(data) { (error, ref) in
            if error != nil {
                Log.e(error!.localizedDescription)
                completion(nil)
            } else {
                Log.i("Saved Photo in Database")
                completion(picture)
            }
        }
    }
    
    static func getUserData(completion: @escaping (RCUser)->()) {
        if let user = auth.currentUser {
            database.child(UserDataString).child(user.uid).observeSingleEvent(of: .value) { (snap) in
                
                let rcUser = RCUser(snapshot: snap)
                rcUser.id = user.uid
                rcUser.email = user.email!
                DataManager.currentFBUser = user
                DataManager.currentAppUser = rcUser
                completion(rcUser)
            }
            
        }
    }
    
    static func updateUserLocation(lat: Double, lon: Double) {
        database.child(UserDataString).child(DataManager.currentFBUser.uid).child("latitude").setValue(lat)
        database.child(UserDataString).child(DataManager.currentFBUser.uid).child("longitude").setValue(lon)
    }
    
    static func updateUserLocation(state: String, country: String) {
        database.child(UserDataString).child(DataManager.currentFBUser.uid).child("country").setValue(country)
        database.child(UserDataString).child(DataManager.currentFBUser.uid).child("state").setValue(state)
    }
    
    
    static func getFilteredData() {
        
    }
    
    static func getAllPictureData(onlyRecent: Bool, completion: @escaping ([RCPicture])->()) {
        if onlyRecent == true {
            let ref = database.child("PictureData")
            ref.observeSingleEvent(of: .value) { (snap) in
                var pictures: [RCPicture] = []
                if let objects = snap.children.allObjects as? [DataSnapshot] {
                    for object in objects {
                        let picture = RCPicture(snapshot: object)
                        pictures.append(picture)
                    }
                    
                    completion(pictures)
                }
            }
        } else {
            database.child("PictureData").observeSingleEvent(of: .value) { (snap) in
                var pictures: [RCPicture] = []
                if let objects = snap.children.allObjects as? [DataSnapshot] {
                    for object in objects {
                        let picture = RCPicture(snapshot: object)
                        pictures.append(picture)
                    }
                    
                    completion(pictures)
                }
            }
        }
    }
    
    static func getAllNewPhotos(newerThan time: Int, completion: @escaping ([RCPicture])->()) {
        let start = Double(time) + 0.1
        let now = Date().timeIntervalSince1970
        let buffer = 60.0 * 10.0
        let ref = database.child("PictureData")
        ref.queryOrdered(byChild: "time").queryStarting(atValue: start).queryEnding(atValue: now + buffer).observeSingleEvent(of: .value) { (snapshot) in
            if let data = snapshot.children.allObjects as? [DataSnapshot] {
                var pictures: [RCPicture] = []
                
                for item in data {
                    let picture = RCPicture(snapshot: item)
                    pictures.append(picture)
                }
                
                completion(pictures)
                
            } else {
                Log.e("Can't get data from snapshot")
            }
        }
    }
    
    static func getPictureData(lat: Double, long: Double, onlyRecent: Bool, compltion: @escaping (RCPicture?)->()) {
        database.child("PictureData").queryOrdered(byChild: "isMostRecentPicture").queryEqual(toValue: onlyRecent).observeSingleEvent(of: .value) { (snap) in
            if let children = snap.children.allObjects as? [DataSnapshot] {
                let best = 0.0001
                let close = 0.005
                
                for child in children {
                    let picture = RCPicture(snapshot: child)
                    
                    let longDiff = abs(picture.longitude - long)
                    let latDiff = abs(picture.latitude - lat)
                    
                    if longDiff > close || latDiff > close {
                        // Lat or Lon is too far off
                        compltion(nil)
                    } else if longDiff < best && latDiff < best {
                        // On current spot
                        compltion(picture)
                    } else if longDiff <= close && latDiff <= close {
                        // Really Close
                        compltion(picture)
                    }
                
                }
            }
        }
    }
    
    static func downloadPicture(pictureData: RCPicture, completion: @escaping (UIImage?)->()) {
        storage.child("Pictures").child(pictureData.id).getData(maxSize: 1024 * 1024 * 20) { (data, error) in
            if error != nil {
                Log.e(error!.localizedDescription)
            } else {
                if let picData = data {
                    if let image = UIImage(data: picData) {
                        Log.i("Got image")
                        completion(image)
                    } else {
                        // Bad Data
                        Log.s("Bad Data")
                    }
                } else {
                    // No Data
                    Log.e("No data handed back")
                }
            }
        }
    }
    
    static func removePhotoFromAllUsers(picture: RCPicture, completion: @escaping (Bool)->()) {
        let ref = database.child("UserData")
        let query = ref.queryOrdered(byChild: "activeChallenge").queryEqual(toValue: picture.id)
        query.observeSingleEvent(of: .value) { (snap) in
            if let objs = snap.children.allObjects as? [DataSnapshot] {
                var ids = [String]()
                
                for obj in objs {
                    let user = RCUser(snapshot: obj)
                    ids.append(user.id)
                }
                
                for id in ids {
                    removePhotoFromUser(id: id)
                }
                
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    private static func removePhotoFromUser(id: String) {
        let ref = database.child("UserData")
        ref.child(id).child("activeChallenge").setValue("")
        ref.child(id).child("activeChallengePoints").setValue(0)
    }
    
    
}
