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
    var page : Int?
    
    @IBOutlet var bottomButton: UIBarButtonItem!
    @IBOutlet var collectionView: UICollectionView!
    var markedIndexPathDict = [Int:NSIndexPath]()
    
    @IBAction func bottomButtonPressed(sender: UIBarButtonItem) {
        photoAlbumBottomButtonAction()
    }
    func getNewPhotoCollection(){
        print("Get new photo collection")
        Flickr.longitude=longitude
        Flickr.latitude=latitude
        Flickr.page = page
        Flickr.sharedInstance().getImageFromFlickrBySearch(downloadCompletionHander);

    }
    
    func deleteMarkedPhotos(){

        for photo in pin.photos {
            if (photo.marked == true) {
                sharedContext.deleteObject(photo)
                photo.deleteImage()
                photo.pin = nil
            }
        }

        collectionView.deleteItemsAtIndexPaths(Array(markedIndexPathDict.values))
        markedIndexPathDict.removeAll()

        CoreDataStackManager.sharedInstance().saveContext()
    }

    func deleteAllPhotos(){
        
        for photo in pin.photos {
            sharedContext.deleteObject(photo)
            photo.deleteImage()
            photo.pin = nil
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        collectionView.reloadData()
    }

    func photoAlbumBottomButtonAction() {
        let result = pin.photos.filter { (photo) in photo.marked  == true }

        if result.count == 0 {
        // New Collection
            page = page! + 1
            deleteAllPhotos()
            getNewPhotoCollection()
        }else{
        // if there is something to be deleted
            deleteMarkedPhotos()
            bottomButton.title = "New Photo Collection"
        }
        
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        populateNavigationBar()
        collectionView.delegate = self
        collectionView.dataSource = self
        page = 1
        if latitude == nil || longitude == nil    {
            return
        }
        print("Latitude, Longitude, Photos : \(latitude) ; \(longitude) ; \(pin?.photos.count)")
        if pin?.photos.count ==  nil || pin?.photos.count==0{
            getNewPhotoCollection()
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
            id = result["id"] as? String{
                let photo = Photo(dictionary :[Photo.Keys.ImagePath : imageUrlString, Photo.Keys.ID : id],context: self.sharedContext)
                photo.pin = self.pin
                print(photoTitle)
                CoreDataStackManager.sharedInstance().saveContext()
                print(photo.pin?.photos.count)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.collectionView.reloadData()
                })
                
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
        
        let jpgImageData = UIImageJPEGRepresentation(image, 1.0)   // if you want to save as JPEG
        let result = jpgImageData!.writeToFile(path, atomically: true)
        return result
        
    }
    
    func savePhotoToDisk(id: String,data : NSData) {
        let photoFileURL = getPathForPhotoId(id)
        saveImage( UIImage(data: data)!,path: photoFileURL.path!)
    }

    func loadPhotoFromDisk(id : String)-> NSURL?{
        let photoFileURL = getPathForPhotoId(id)
        
        if NSFileManager.defaultManager().fileExistsAtPath(photoFileURL.path!) {
            return photoFileURL
        }else{
            return nil
        }
    }

    
    func backToMapView(){
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    // MARKDOWN : UICollectionView
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        self.pin.photos[indexPath.row].marked = !self.pin.photos[indexPath.row].marked
        if (self.pin.photos[indexPath.row].marked) {
            collectionView.cellForItemAtIndexPath(indexPath)?.alpha = 0.3
            markedIndexPathDict[indexPath.row] = indexPath
        }else{
            collectionView.cellForItemAtIndexPath(indexPath)?.alpha = 1
            markedIndexPathDict.removeValueForKey(indexPath.row)
        }

        let result = pin.photos.filter { (photo) in photo.marked  == true }
        print("Marked photo count:\(result.count)")
        if result.count == 0 {
            bottomButton.title = "New Photo Collection"
            print("set new Collection")
        }else{
            bottomButton.title = "Remove Selection"
            print("remove pictures")
        }
    }
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        print("deselect photo")
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
        
        if let image = self.pin.photos[indexPath.row].getImage(collectionView) {
            cell.imageView?.image = image
            
        }else{
            cell.imageView?.image = UIImage(named: "photoPlaceholder")
        }
        return cell
    }
    
}