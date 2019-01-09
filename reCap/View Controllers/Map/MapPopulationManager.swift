////
//  MapPopulationManager.swift
//  HealthApp
//
//  Created by App Center on 12/28/18.
//  Copyright © 2018 rlukedavis. All rights reserved.
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
                    
                    for picture in newData {
                        picture.convertToRealm()
                    }
                }
            } else {
                Log.d("Requesting all photos")
                FirebaseHandler.getAllPictureData(onlyRecent: true, completion: { (pictureData) in
                    Log.d("Caching \(pictureData.count) new photos")
                    
                    for picture in pictureData {
                        picture.convertToRealm()
                    }
                })
            }
        }
        
    }
}
