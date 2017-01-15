//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/15/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var image: NSData?
    @NSManaged public var pin: Pin?

}
