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
    
    func downloadAndSavePhotos(pin: Pin, callback: @escaping (_ error: String?, _ result: Bool?) -> Void) {
        
        VirtualTouristClient.shared.searchByLatLon(latitude: pin.latitude, longitude: pin.longitude, pageNumber: pin.flickrPage) { (error, photos) in
            if photos != nil {
                self.delegate.stack.performBackgroundBatchOperation { (workerContext) in
                    for photo in photos! {
                        print("Downloading \(photo.photoUrl)")
                        let imageData = NSData(contentsOf: URL(string: photo.photoUrl)!)
                        let photoToSave = Photo(image: imageData, imageUrl: photo.photoUrl, context: workerContext)
                        photoToSave.pin = pin
                        print("Finished downloading \(photo.photoUrl)")
                        //pin.addToPhotos(photoToSave)
                    }
                    print("Finished downloading all photos")
                    callback(nil, true)
                }
            }
        }
    }
}
