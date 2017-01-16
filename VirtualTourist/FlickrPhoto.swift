//
//  File.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/15/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//

import Foundation

struct FlickrPhoto {
    var photoId: Double
    var photoUrl: NSURL
    
    init(id: Double, url: NSURL) {
        self.photoId = id
        self.photoUrl = url
    }
}
