//
//  RealmHelper.swift
//  reCap
//
//  Created by Kaleb Cooper on 4/21/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation
import RealmSwift

public class RealmHelper {
    
    static var realm: Realm? = try? Realm()
    
    enum PictureDataError: Error {
        case NoCachedData
    }
    
    static func getCachedPhotoData(token: (NotificationToken)->(),
                                   updates: @escaping ([RCPicture]?, [RCPicture]?)->(),
                                   completion: @escaping (Error?, [RCPicture]?)->()) {
        guard let realm = realm else { return }
        let photoData = realm.objects(PictureData.self)
        let notificationToken = photoData.observe { (changes) in
            switch changes {
            case .initial(let photos):
                if photoData.count > 0 {
                    // We have cached data
                    let results = Array(photoData)
                    
                    var converted: [RCPicture] = []
                    results.forEach { (picture) in
                        let convert = picture.convertToRCPicture()
                        converted.append(convert)
                    }
                    
                    completion(nil, converted)
                } else {
                    // No cached data available
                    completion(PictureDataError.NoCachedData, nil)
                }
            case .update(let photos, deletions: let deleted, insertions: let added, modifications: let changed):
                Log.i(photos.count)
                Log.i(deleted)
                let del: [RCPicture] = deleted.map({
                    return photos[$0].convertToRCPicture()
                })
                Log.i(added)
                let add: [RCPicture] = added.map({
                    return photos[$0].convertToRCPicture()
                })
                updates(add, del)
            case .error(let error):
                Log.e(error.localizedDescription)
                break
            }
        }
        
        token(notificationToken)
    }
    
    static func getPhotoFor(lat: Double, lon: Double) -> RCPicture? {
        guard let realm = realm else { return nil }
        if let photo = realm.objects(PictureData.self).filter("latitude == \(lat) AND longitude == \(lon)").first {
            let converted = photo.convertToRCPicture()
            return converted
        } else {
            return nil
        }
    }
    
    static func getPhotos(in group: String) -> [RCPicture]? {
        guard let realm = realm else { return nil }
        let realmPhotos = realm.objects(PictureData.self).filter("groupID = %@", group).sorted(byKeyPath: "time", ascending: false)
        if realmPhotos.count > 0 {
            var photos = [RCPicture]()
            for photo in realmPhotos {
                let converted = photo.convertToRCPicture()
                photos.append(converted)
            }
            return photos
        } else {
            return nil
        }
    }
    
}


