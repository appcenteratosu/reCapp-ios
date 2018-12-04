//
//  ProfileImageCacher.swift
//  reCap
//
//  Created by App Center on 12/3/18.
//  Copyright © 2018 Kaleb Cooper. All rights reserved.
//

import Foundation
import UIKit

class ProfileImageCacher {
    private static var cache: NSCache = NSCache<NSString, NSData>()
    
    public static func AddNewProfilePicture(uid: String, image: UIImage) {
        let nsUID = NSString(string: uid)

        guard let data = UIImagePNGRepresentation(image) else {
            Log.e("Could not parse UIImage to Data")
            return
        }

        let nsdata = NSData(data: data)
        
        cache.setObject(nsdata, forKey: nsUID)
        Log.i("Cached image for UID: \(uid)")
    }
    
    public static func requestProfilePictureFor(uid: String) -> UIImage? {
        if let nsdata = cache.object(forKey: NSString(string: uid)) {
            let data = nsdata as Data
            if let image = UIImage(data: data) {
                Log.i("Request Granted: Handing back image")
                return image
            } else {
                Log.e("Could not parse Image From Data")
                return nil
            }
        } else {
            Log.e("Could not find image in Cache")
            return nil
        }
    }
    
    
}
