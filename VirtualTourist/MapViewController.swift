//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by hunglun on 1/25/16.
//  Copyright © 2016 hunglun. All rights reserved.
//
//


import UIKit
import MapKit

class  MapViewController: UIViewController,MKMapViewDelegate,UIGestureRecognizerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    func edit(){
        //TODO 0.5 : edit
    }
    
    func populateNavigationBar() {
        
//        navigationItem.rightBarButtonItem  = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "edit")
//        navigationItem.title = "On The Map"
    }

    
    func navigateToPhotoAlbumView(){
        let nextController = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController")
        navigationController?.pushViewController(nextController, animated: false)
    }
    
    func backToMapView(){
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func handleLongPressGesture(sender: UITapGestureRecognizer) {
            let point = sender.locationInView(self.mapView) //locationInView:self.mapView
            let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Hello"
            self.mapView.addAnnotation(annotation)
    }


    func addTapHoldGesture() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
        longPressRecognizer.delegate = self
        self.mapView.addGestureRecognizer(longPressRecognizer)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        populateNavigationBar()
        addTapHoldGesture()
        print(NSUserDefaults.standardUserDefaults().floatForKey("myValue"))
        NSUserDefaults.standardUserDefaults().setFloat(22.5, forKey: "myValue")
        
        restoreMapRegion(false)
     }
    // MARK: - Save the zoom level helpers
    
    // Here we use the same filePath strategy as the Persistent Master Detail
    // A convenient property
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }

    override func viewWillAppear(animated: Bool) {
        
        
        super.viewWillAppear(animated)
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        // We will create an MKPointAnnotation for each student in "locations". The
        // point annotations will be stored in this array, and then provided to the map view.
        var annotations = [MKPointAnnotation]()
        
        // The "locations" array is loaded with the sample data below. We are using the dictionaries
        // to create map annotations. This would be more stylish if the dictionaries were being
        // used to create custom structs. Perhaps StudentLocation structs.

        //self.mapView.centerCoordinate = coordinate
        
        /*
        for student in locations ?? [] {
            
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            let lat = CLLocationDegrees(student.latitude)
            let long = CLLocationDegrees(student.longitude )
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let first = student.firstName
            let last = student.lastName
            let mediaURL = student.mediaURL
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(first) \(last)"
            annotation.subtitle = mediaURL
            
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        */
        // When the array is complete, we add the annotations to the map.
        self.mapView.addAnnotations(annotations)
        
        
        
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
 
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView

    }
 
    
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == annotationView.rightCalloutAccessoryView {
//            let app = UIApplication.sharedApplication()
  //          app.openURL(NSURL(string: annotationView.annotation!.subtitle!!)!)
            navigateToPhotoAlbumView()
/*            let photoAlbumViewController = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController")
            presentViewController(photoAlbumViewController, animated: true, completion: nil) */
        }
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }

    
}








