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
    
    static func getCachedPhotoData(completion: (Error?, [RCPicture]?)->()) {
        guard let realm = realm else { return }
        let photoData = realm.objects(PictureData.self)
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
    }
    
    
}


