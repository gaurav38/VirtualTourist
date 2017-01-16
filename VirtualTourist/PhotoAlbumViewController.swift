//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/10/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pinCoordinates: CLLocationCoordinate2D?
    var virtualTouristClient = VirtualTouristClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpMapView()
    }

    @IBAction func newCollectionButtonPressed(_ sender: Any) {
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    func setUpMapView() {
        mapView.delegate = self
        
        if let pinCoordinates = pinCoordinates {
            let span = MKCoordinateSpanMake(0.005, 0.005)
            let region = MKCoordinateRegion(center: pinCoordinates, span: span)
            mapView.setRegion(region, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = pinCoordinates
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pin.animatesDrop = true
        return pin
    }
}
