//
//  DownloadService.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/18/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//

import Foundation
import UIKit

class DownloadService {
    
    static let shared = DownloadService()
    var delegate = UIApplication.shared.delegate as! AppDelegate
    
    func searchFlickrAndSavePhotos(pin: Pin, callback: @escaping (_ error: String?, _ result: Bool?) -> Void) {
        VirtualTouristClient.shared.searchByLatLon(latitude: pin.latitude, longitude: pin.longitude, pageNumber: pin.flickrPage) { (error, photos) in
            if photos != nil {
                self.delegate.stack.performBackgroundBatchOperation { (workerContext) in
                    for photo in photos! {
                        let photoToSave = Photo(image: nil, imageUrl: photo.photoUrl, context: workerContext)
                        photoToSave.pin = pin
                    }
                    print("Created all Photo entities.")
                }
            }
        }
    }
    
    func downloadPhoto(for photo: Photo) {
        self.delegate.stack.performBackgroundBatchOperation { (workerContext) in
            let imageData = NSData(contentsOf: URL(string: photo.imageUrl!)!)
            photo.image = imageData
        }
    }
}
