//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by hunglun on 1/26/16.
//  Copyright © 2016 hunglun. All rights reserved.
//


import UIKit
import CoreData
// MARK: - Globals
// Map Kit Constants
let BOUNDING_BOX_HALF_WIDTH = 0.01
let BOUNDING_BOX_HALF_HEIGHT = 0.01
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0
class PhotoAlbumViewController : UIViewController , UICollectionViewDelegate, UICollectionViewDataSource{
    var longitude : Double?
    var latitude : Double?
    var photos = [UIImage]() //UIImage(data: imageData)
    var pin : Pin!

    
    @IBOutlet var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        populateNavigationBar()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        if latitude == nil || longitude == nil    {
            return
        }
        print("Photos : \(pin?.photos.count)")
        if pin?.photos.count ==  nil || pin?.photos.count==0{
//            getImageFromFlickrBySearch(methodArguments)
            Flickr.longitude=longitude
            Flickr.latitude=latitude
            Flickr.sharedInstance().getImageFromFlickrBySearch(downloadCompletionHander);
        }
    }

    func populateNavigationBar() {
        
        navigationItem.leftBarButtonItem  = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "backToMapView")

    }
    // MARK: Lat/Lon Manipulation
    
    func createBoundingBoxString() -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude! - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude! - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude! + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude! + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    // MARK: Escape HTML Parameters
    
       // download completion handler
    func downloadCompletionHander (result: AnyObject!, error: NSError?) -> Void {
        if let photoTitle = result["title"] as? String, /* non-fatal */
            imageUrlString = result["url_m"] as? String,
            imageURL = NSURL(string: imageUrlString),
            id = result["id"] as? String{
                
                var imageData : NSData?
                
                if let localURL = self.loadPhotoFromDisk(id) {
                    imageData = NSData(contentsOfURL: localURL)
                    print("found \(localURL.path)")
                    
                }else {
                    imageData = NSData(contentsOfURL: imageURL)
                    self.savePhotoToDisk(id ,data: imageData!)
                }
                
                let photo = Photo(dictionary :[Photo.Keys.ImagePath : self.loadPhotoFromDisk(id)!.path!, Photo.Keys.ID : id],context: self.sharedContext)
                photo.pin = self.pin
                print(photoTitle)
                CoreDataStackManager.sharedInstance().saveContext()
                print(self.pin?.photos.count)
                print(photo.pin?.photos.count)
                self.collectionView.reloadData()
        }
    }

    
    var sharedContext : NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func getPathForPhotoId(id:String) -> NSURL{
        let filename = "\(id).jpg"
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        let pathArray = [dirPath, filename]
        let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!
        return fileURL
    }

    func saveImage (image: UIImage, path: String ) -> Bool{
        
//        let pngImageData = UIImagePNGRepresentation(image)
        let jpgImageData = UIImageJPEGRepresentation(image, 1.0)   // if you want to save as JPEG
        let result = jpgImageData!.writeToFile(path, atomically: true)
        
        return result
        
    }
    
    func savePhotoToDisk(id: String,data : NSData) {
        let photoFileURL = getPathForPhotoId(id)
        saveImage( UIImage(data: data)!,path: photoFileURL.path!)

        //TODO: save imageData to photoFileURL
    }

    func loadPhotoFromDisk(id : String)-> NSURL?{
        let photoFileURL = getPathForPhotoId(id)
        if NSFileManager.defaultManager().fileExistsAtPath(photoFileURL.path!) {
            return photoFileURL
        }else{
            return nil
        }
    }


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func backToMapView(){
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    // MARKDOWN : UICollectionView
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("select photo")
        
    }
    
    func collectionView(tableView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(pin?.photos.count)
        if pin?.photos ==  nil {
            return 0
        }
        return pin!.photos.count
    }
    
    func collectionView(tableView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView?.dequeueReusableCellWithReuseIdentifier("PhotoAlbumCollectionViewCell", forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        
        cell.imageView?.image = self.pin.photos[indexPath.row].image
        
        return cell
    }
    
}