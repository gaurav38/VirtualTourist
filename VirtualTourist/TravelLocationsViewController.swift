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

class TravelLocationsViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var gestureRecognizer: UILongPressGestureRecognizer!
    var appDelegate = UIApplication.shared.delegate
    var locationManager = CLLocationManager()
    var selectedCoordinate: CLLocationCoordinate2D?
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! PhotoAlbumViewController
        if let selectedCoordinate = selectedCoordinate {
            destination.pinCoordinates = selectedCoordinate
        }
    }

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
        selectedCoordinate = view.annotation?.coordinate
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        vc.pinCoordinates = selectedCoordinate
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        self.navigationController?.pushViewController(vc, animated: true)
        //self.performSegue(withIdentifier: "showAlbum", sender: self)
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
