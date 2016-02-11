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
import CoreData
class  MapViewController: UIViewController,MKMapViewDelegate,UIGestureRecognizerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    var selectedPin : Pin?
    var pins = [Pin]()
    
    func edit(){
        //TODO 0.5 : edit
    }
    
    func populateNavigationBar() {
        
//        navigationItem.rightBarButtonItem  = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "edit")
//        navigationItem.title = "On The Map"
    }

 
    func navigateToPhotoAlbumView(pinID : String){
        let nextController = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        for pin in pins {
            print("Pin ID: \(pin.id)")
            if (pinID == "\(pin.id)") {
                nextController.pin = pin
                nextController.latitude = pin.latitude
                nextController.longitude = pin.longitude
                
            }
        }
        navigationController?.pushViewController(nextController, animated: false)
    }
   
    func backToMapView(){
        navigationController?.popToRootViewControllerAnimated(true)
    }

    var sharedContext : NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    func handleLongPressGesture(sender: UILongPressGestureRecognizer) {
        if sender.state == .Ended {

            let point = sender.locationInView(self.mapView) //locationInView:self.mapView
            let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate


            self.mapView.addAnnotation(annotation)
            let pin = Pin(dictionary :[Pin.Keys.latitude : coordinate.latitude, Pin.Keys.Longitude : coordinate.longitude],context: sharedContext)
            annotation.title = "\(pin.id)"
            pins.append(pin)
            CoreDataStackManager.sharedInstance().saveContext()
            print("in long press gesture")
        }
    }


    func addTapHoldGesture() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
        longPressRecognizer.delegate = self
        self.mapView.addGestureRecognizer(longPressRecognizer)
    }
    
    func fetchAllPins() -> [Pin]{
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch _ {
            return [Pin]()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateNavigationBar()
        addTapHoldGesture()
        print(NSUserDefaults.standardUserDefaults().floatForKey("myValue"))
        NSUserDefaults.standardUserDefaults().setFloat(22.5, forKey: "myValue")
    

        restoreMapRegion(false)
        pins = fetchAllPins()
        for pin in pins {
            let annotation = MKPointAnnotation()
            print(pin.longitude)
            print(pin.latitude)
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            annotation.title = "\(pin.id)"

            
            self.mapView.addAnnotation(annotation)
        }
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
        
        
        
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
 
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        pinView!.canShowCallout = false
        
        return pinView

    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
           navigateToPhotoAlbumView(((view.annotation?.title)!)!);
        print(view.annotation!.title)

    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {

        print("\(view.annotation!.title) deselect")
    }

    
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

        if control == annotationView.rightCalloutAccessoryView {
//            let app = UIApplication.sharedApplication()
  //          app.openURL(NSURL(string: annotationView.annotation!.subtitle!!)!)

            navigateToPhotoAlbumView(((annotationView.annotation?.title)!)!);
/*            let photoAlbumViewController = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController")
            presentViewController(photoAlbumViewController, animated: true, completion: nil) */
        }
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }

 
    
}








