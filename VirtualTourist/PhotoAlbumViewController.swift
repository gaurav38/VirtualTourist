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
    var currentPage: Int16!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateItemSizeBasedOnOrientation()
        setUpMapView()
        collectionView.delegate = self
        print("Number of photos = \((pin?.photos?.count)!)")
        collectionView.dataSource = self
        currentPage = pin?.flickrPage
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
        deleteAllPhotos { (result) in
            if result! {
                self.getPinFromBackgroundContext { (result, pin) in
                    if let pin = pin {
                        getNewPhotos(newPin: pin)
                    }
                }
            }
        }
    }
    
    func displayError(error: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Error!", message: error, preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
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

extension PhotoAlbumViewController {
    func deleteAllPhotos(callback: (_ result: Bool?) -> Void) {
        let photos = pin?.photos
        if let photos = photos {
            for photo in photos {
                fetchedResultsController?.managedObjectContext.delete(photo as! NSManagedObject)
            }
            delegate.stack.save()
            callback(true)
        }
    }
    
    func getNewPhotos(newPin: Pin) {
        currentPage = currentPage + 1
        pin?.flickrPage = currentPage
        do {
            try delegate.stack.backgroundContext.save()
        } catch {
            print("Error saving background context after saving page number of Pin.")
        }
        
        print("Downloading photos from page: \(pin?.flickrPage)")
        DownloadService.shared.searchFlickrAndSavePhotos(pin: newPin) { (error, result) in
            if result! {
                print("Flickr search finished.")
            } else {
                if let error = error {
                    self.displayError(error: error)
                }
            }
        }
    }
    
    func getPinFromBackgroundContext(callback: (_ result: Bool, _ pin: Pin?) -> Void) {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                              NSSortDescriptor(key: "longitude", ascending: true)]
        let latPred = NSPredicate(format: "latitude = %@", argumentArray: [pin!.latitude])
        let lonPred = NSPredicate(format: "longitude = %@", argumentArray: [pin!.longitude])
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [latPred, lonPred])
        fr.predicate = andPredicate
        let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: delegate.stack.backgroundContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fc.performFetch()
        } catch {
            print("Error fetching Pin in background context.")
            callback(false, nil)
        }
        let selectedPin = fc.fetchedObjects?[0] as! Pin
        print("Found a saved pin. latitude = \(selectedPin.latitude), longitude = \(selectedPin.longitude)")
        callback(true, selectedPin)
    }
}
