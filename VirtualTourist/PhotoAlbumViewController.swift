//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/10/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: CoreDataCollectionViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var pin: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpMapView()
        collectionView.delegate = self
        print("Number of photos = \((pin?.photos?.count)!)")
        collectionView.dataSource = self
        updateItemSizeBasedOnOrientation()
    }
    
    func updateItemSizeBasedOnOrientation()
    {
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0
        let space: CGFloat = 3.0
        
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            width = (collectionView.frame.size.width - (2 * space)) / 3.0
            height = (collectionView.frame.size.height - (3 * space)) / 4.0
        } else if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            width = (collectionView.frame.size.width - (4 * space)) / 5.0
            height = (collectionView.frame.size.height - (2 * space)) / 3.0
        }
        if height > 0 && width > 0 {
            var itemSize: CGSize = CGSize()
            itemSize.height = height
            itemSize.width = width
            
            flowLayout.minimumInteritemSpacing = space
            flowLayout.itemSize = itemSize
        }
    }
    
    func subscribeToOrientationChangeNotification()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(updateItemSizeBasedOnOrientation), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    func unsubscribeToOrientationChangeNotification()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    @IBAction func newCollectionButtonPressed(_ sender: Any) {
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    func setUpMapView() {
        mapView.delegate = self
        
        if let pin = pin {
            let pinCoordinates = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
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

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageViewCell", for: indexPath) as! ImageViewCell
        
        let photo = fetchedResultsController?.object(at: indexPath) as? Photo
        
        if let photo = photo {
            if photo.image == nil {
                cell.activityIndicator.startAnimating()
            } else {
                cell.image.image = UIImage(data: photo.image! as Data)
                cell.activityIndicator.stopAnimating()
            }
        }
        
        return cell
    }
}
