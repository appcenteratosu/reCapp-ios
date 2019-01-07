////
//  MapNetworkService.swift
//  HealthApp
//
//  Created by App Center on 12/28/18.
//  Copyright © 2018 rlukedavis. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import CoreLocation

class MapNetworkService {
    let user = CLLocation(latitude: CLLocationDegrees(exactly: 36.120768)!,
                          longitude: CLLocationDegrees(exactly: -97.064382)!)
    
    func getPictureData(in range: [Double], completion: @escaping ([RCPicture]?)->()) {
        let pictureRef = FirebaseHandler.database.child("PictureData")
        
        
        let q = pictureRef.queryOrdered(byChild: "longitude").queryStarting(atValue: range[3]).queryEnding(atValue: range[1])
        q.observeSingleEvent(of: .value) { (snap) in
            if let items = snap.children.allObjects as? [DataSnapshot] {
                
                var picturesInRange: [RCPicture] = []
                
                for item in items {
                    let picture = RCPicture(snapshot: item)
                    let picCoords = CLLocation(latitude: CLLocationDegrees(exactly: picture.latitude)!,
                                               longitude: CLLocationDegrees(exactly: picture.longitude)!)
                    
                    if self.user.isIn(range: 50, of: picCoords) {
                        Log.d("Success!")
                        picturesInRange.append(picture)
                    }
                }
                completion(picturesInRange)
            } else {
                Log.e("Could not reach database for query")
            }
        }
        
    }

    func downloadImage(for picture: RCPicture, completion: @escaping (UIImage?)->()) {
        let ref = FirebaseHandler.storage.child("Pictures").child(picture.id)
        ref.getData(maxSize: 1024 * 1024 * 20) { (data, error) in
            guard error == nil else {
                Log.e(error!.localizedDescription)
                completion(nil)
                return
            }
            
            guard data != nil else { return }
            
            if let image = UIImage(data: data!) {
                completion(image)
            } else {
                Log.e("Bad Data")
                completion(nil)
            }
        }
    }


}
