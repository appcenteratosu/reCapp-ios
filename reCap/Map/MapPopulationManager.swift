////
//  MapPopulationManager.swift
//  HealthApp
//
//  Created by App Center on 12/28/18.
//  Copyright © 2020 OSU App Center. All rights reserved.
//

import Foundation

class MapPopulationManager {
    
    private static var willWait: Bool = false
    public static func shouldWaitForAppDelegate() {
        willWait = true
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { (timer) in
            timer.invalidate()
            willWait = false
            MapPopulationManager.initializeMapDataSource()
        }
    }
    
    public static func initializeMapDataSource() {
        guard let realm = RealmHelper.realm else { return }
        if willWait == false {
            Log.d("Initializing Map")
            
            let data = realm.objects(PictureData.self)
            let mostRecent = data.max { (p1, p2) -> Bool in
                return p1.time < p2.time
            }
            
            if let recent = mostRecent {
                Log.d("Requesting New photos")
                FirebaseHandler.getAllNewPhotos(newerThan: recent.time) { (newData) in
                    Log.d("Caching \(newData.count) new photos")
                    if newData.count > 0 {
                        for picture in newData {
                            let path = FirebaseHandler.storage.child("Pictures").child(picture.id)
                            path.getData(maxSize: 1024 * 10, completion: { (data, error) in
                                guard error == nil else { return }
                                guard let data = data else { return }
                                if path.fullPath.contains(picture.id) {
                                    picture.image = data
                                    picture.convertToRealm()
                                }
                            })
                        }
                    } else {
                        Log.i("No New Data to Cache")
                    }
                }
            } else {
                Log.d("Requesting all photos")
                FirebaseHandler.getAllPictureData(onlyRecent: true, completion: { (pictureData) in
                    Log.d("Caching \(pictureData.count) new photos")
                    
                    for picture in pictureData {
                        let path = FirebaseHandler.storage.child("Pictures").child(picture.id)
                        path.getData(maxSize: 1024 * 1024 * 10, completion: { (data, error) in
                            guard error == nil else { return }
                            guard let data = data else { return }
                            if path.fullPath.contains(picture.id) {
                                picture.convertToRealm(with: nil, dataImage: data)
                            }
                        })
                    }
                })
            }
        }
        
    }
    
    public static func added(new photo: RCPicture) {
        photo.convertToRealm()
    }
    
}
