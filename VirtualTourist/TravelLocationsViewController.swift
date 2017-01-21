//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/10/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class TravelLocationsViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var gestureRecognizer: UILongPressGestureRecognizer!
    var locationManager = CLLocationManager()
    var fr: NSFetchRequest<NSFetchRequestResult>!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    var savedPins = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefaultsHelper.isFirstLaunch() {
            setUpLocationManager()
        } else {
            centerMapView(toCoordinate: UserDefaultsHelper.getSavedCoordinates(),
                          latitudeDelta: UserDefaultsHelper.getSavedLatitudeDelta(),
                          longitudeDelta: UserDefaultsHelper.getSavedLongitudeDelta())
        }
        fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                              NSSortDescriptor(key: "longitude", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        performFetch()
        savedPins = (fetchedResultsController?.fetchedObjects as? [Pin])!
        
        print("Fetched saved pins")
        for savedObject in (fetchedResultsController?.fetchedObjects)! {
            let pin = savedObject as! Pin
            print("latitude = \(pin.latitude), longitude = \(pin.longitude)")
        }
        setUpMapView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func setUpMapView() {
        gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(dropPin))
        gestureRecognizer.minimumPressDuration = 1.0
        gestureRecognizer.allowableMovement = 1
        mapView.addGestureRecognizer(gestureRecognizer)
        mapView.delegate = self
        
        if !savedPins.isEmpty {
            for pin in savedPins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func dropPin(gestureRecognizer: UIGestureRecognizer){
        
        if gestureRecognizer.state == UIGestureRecognizerState.ended {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
            let pin = Pin(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude, flickrPage: 1, context: delegate.stack.backgroundContext)
            
            do {
                try delegate.stack.backgroundContext.save()
            } catch {
                print("Error saving Pin")
            }
            
            DownloadService.shared.searchFlickrAndSavePhotos(pin: pin) { (error, result) in
                if result != nil {
                    print("Flickr search finished.")
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pin.animatesDrop = true
        return pin
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let latitudeDelta = mapView.region.span.latitudeDelta
        let longitudeDelta = mapView.region.span.longitudeDelta
        UserDefaultsHelper.save(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        UserDefaultsHelper.save(coordinates: mapView.centerCoordinate)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        searchPin(coordinates: (view.annotation?.coordinate)!) { (error, pin) -> Void in
            if let pin = pin {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: true)]
                let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
                fetchRequest.predicate = predicate
                let fc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
                
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
                vc.pin = pin
                vc.fetchedResultsController = fc
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
                
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                print(error!)
            }
        }
    }
    
    func centerMapView(toCoordinate coordinate: CLLocationCoordinate2D, latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}

extension TravelLocationsViewController: CLLocationManagerDelegate {
    
    func setUpLocationManager() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        if UserDefaultsHelper.isFirstLaunch() {
            print("locations = \(locValue.latitude) \(locValue.longitude)")
            UserDefaultsHelper.save(coordinates: locValue)
            UserDefaultsHelper.save(latitudeDelta: 0.005, longitudeDelta: 0.005)
            centerMapView(toCoordinate: locValue, latitudeDelta: CLLocationDegrees(0.005), longitudeDelta: CLLocationDegrees(0.055))
        }
    }
}

extension TravelLocationsViewController {
    func searchPin(coordinates: CLLocationCoordinate2D, callback: @escaping (_ error: String?, _ pin: Pin?) -> Void) {
        let latPred = NSPredicate(format: "latitude = %@", argumentArray: [coordinates.latitude])
        let lonPred = NSPredicate(format: "longitude = %@", argumentArray: [coordinates.longitude])
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [latPred, lonPred])
        fr.predicate = andPredicate
        
        performFetch()
        let selectedPin = fetchedResultsController?.fetchedObjects?[0] as! Pin
        print("Found a saved pin. latitude = \(selectedPin.latitude), longitude = \(selectedPin.longitude)")
        callback(nil, selectedPin)
    }
    
    func performFetch() {
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Error fetching Pin")
        }
    }
}
