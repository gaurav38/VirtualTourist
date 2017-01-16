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

class TravelLocationsViewController: CoreDataCollectionViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var gestureRecognizer: UILongPressGestureRecognizer!
    var locationManager = CLLocationManager()
    var fr: NSFetchRequest<NSFetchRequestResult>!
    
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
        setUpMapView()
        //fetchSavedPins()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let destination = segue.destination as! PhotoAlbumViewController
//        if let selectedCoordinate = selectedCoordinate {
//            destination.pinCoordinates = selectedCoordinate
//        }
//    }

}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func setUpMapView() {
        gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(dropPin))
        mapView.addGestureRecognizer(gestureRecognizer)
        mapView.delegate = self
    }
    
    func dropPin(gestureRecognizer: UIGestureRecognizer){
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        mapView.addAnnotation(annotation)
        
        _ = Pin(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude, context: delegate.stack.context)
        delegate.stack.save()
        //fetchSavedPins()
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
        
        FetchPin(coordinates: (view.annotation?.coordinate)!) { (error, pin) -> Void in
            if let pin = pin {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
                vc.pin = pin
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
    func FetchPin(coordinates: CLLocationCoordinate2D, callback: @escaping (_ error: String?, _ pin: Pin?) -> Void) {
        fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                              NSSortDescriptor(key: "longitude", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        let latPred = NSPredicate(format: "latitude = %@", argumentArray: [coordinates.latitude])
        let lonPred = NSPredicate(format: "longitude = %@", argumentArray: [coordinates.longitude])
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [latPred, lonPred])
        fr.predicate = andPredicate
        
        fetchPins()
        let selectedPin = fetchedResultsController?.fetchedObjects?[0] as! Pin
        print("Found a saved pin. latitude = \(selectedPin.latitude), longitude = \(selectedPin.longitude)")
        callback(nil, selectedPin)
    }
    
    func fetchSavedPins() {
        fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                              NSSortDescriptor(key: "longitude", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchPins()
        savedPins.removeAll()
        savedPins = (fetchedResultsController?.fetchedObjects as? [Pin])!
        
        print("Fetched saved pins")
        for pin in savedPins {
            print("latitude = \(pin.latitude), longitude = \(pin.longitude)")
        }
    }
    
    func fetchPins() {
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Error fetching Pin")
        }
    }
}
