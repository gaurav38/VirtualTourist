//
//  VirtualTouristClient.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/15/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//

import Foundation

class VirtualTouristClient {
    
    static let shared = VirtualTouristClient()
    
    func searchByLatLon(latitude: Double, longitude: Double, pageNumber: Int16, callback: @escaping (_ error: String?, _ response: [FlickrPhoto]?, _ numberOfPages: Int16?) -> ()) {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Page: String(pageNumber)
        ]
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String : AnyObject]))
        
        // create network request
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                callback(error, nil, nil)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String: AnyObject]
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            guard let numberOfPages = photosDictionary["pages"] as? Int16 else {
                return
            }
            
            guard let photos = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                return
            }
            
            callback(nil, self.getRandomFlickrPhotos(from: photos), numberOfPages)
        })
        
        // start the task!
        task.resume()
    }
    
    func getRandomFlickrPhotos(from photos: [[String: AnyObject]]) -> [FlickrPhoto] {
        let startingPoint = Int(arc4random_uniform(UInt32(photos.count - Constants.Flickr.NumberOfPhotosToSelect)))
        var currentPhotoNumber = 0
        var numberOfPhotosPicked = 0
        var finalPhotoArray = [FlickrPhoto]()
        
        for photo in photos {
            if currentPhotoNumber >= startingPoint {
                if numberOfPhotosPicked < Constants.Flickr.NumberOfPhotosToSelect {
                    if let photoId = photo[Constants.FlickrResponseKeys.Id] as? String, let photoUrl = photo[Constants.FlickrParameterValues.MediumURL] as? String {

                        finalPhotoArray.append(FlickrPhoto(id: photoId, url: photoUrl))
                        numberOfPhotosPicked += 1
                    }
                }
            }
            currentPhotoNumber += 1
        }
        return finalPhotoArray
    }
    
    fileprivate func bboxString(latitude: Double, longitude: Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    fileprivate func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
