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
    let session = URLSession.shared
    
    func searchFlickrAndSavePhotos(pin: Pin, pageNumber: Int16, callback: @escaping (_ error: String?, _ result: Bool) -> Void) {
        VirtualTouristClient.shared.searchByLatLon(latitude: pin.latitude, longitude: pin.longitude, pageNumber: pageNumber) { (error, photos, numberOfPages) in
            if photos != nil {
                self.delegate.stack.performBackgroundBatchOperation { (workerContext) in
                    pin.flickrPage = numberOfPages!
                    for photo in photos! {
                        let photoToSave = Photo(image: nil, imageUrl: photo.photoUrl, context: workerContext)
                        photoToSave.pin = pin
                        do {
                            try workerContext.save()
                        } catch {
                            callback("Error while saving background context after creating Photo entity.", false)
                        }
                    }
                    print("Created all Photo entities.")
                    callback(nil, true)
                }
            } else {
                callback("Error searching photos in Flickr.", false)
            }
        }
    }
    
    func downloadImage(imagePath:String, completionHandler: @escaping (_ imageData: Data?, _ errorString: String?) -> Void) {
        let imgURL = NSURL(string: imagePath)
        let request = NSURLRequest(url: imgURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            guard error == nil else {
                completionHandler(nil, "Could not download image \(imagePath)")
                return
            }
            
            completionHandler(data, nil)
        }
        
        task.resume()
    }
}
