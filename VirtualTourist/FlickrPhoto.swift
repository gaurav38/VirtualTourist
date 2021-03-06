//
//  File.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/15/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//

import Foundation

struct FlickrPhoto {
    let photoId: String
    let photoUrl: String
    
    init(id: String, url: String) {
        self.photoId = id
        self.photoUrl = url
    }
}
