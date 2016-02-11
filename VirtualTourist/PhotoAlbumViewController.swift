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

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "8ba389c3eed8a5d6329c57c0f20ef23b"
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
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
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]



        print("Photos : \(pin?.photos.count)")
        if pin?.photos.count ==  nil || pin?.photos.count==0{
            getImageFromFlickrBySearch(methodArguments)
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
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    // MARK: Flickr API
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int) {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                dispatch_async(dispatch_get_main_queue(), {
//                    self.setUIEnabled(enabled: true)
                })
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                dispatch_async(dispatch_get_main_queue(), {
  //                  self.setUIEnabled(enabled: true)
                })
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                dispatch_async(dispatch_get_main_queue(), {
    //                self.setUIEnabled(enabled: true)
                })
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                dispatch_async(dispatch_get_main_queue(), {
      //              self.setUIEnabled(enabled: true)
                })
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                dispatch_async(dispatch_get_main_queue(), {
        //            self.setUIEnabled(enabled: true)
                })
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                dispatch_async(dispatch_get_main_queue(), {
          //          self.setUIEnabled(enabled: true)
                })
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                dispatch_async(dispatch_get_main_queue(), {
            //        self.setUIEnabled(enabled: true)
                })
                print("Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotosVal > 0 {
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    dispatch_async(dispatch_get_main_queue(), {
              //          self.setUIEnabled(enabled: true)
                    })
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
//                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))

                dispatch_async(dispatch_get_main_queue(), {
                    for photoDictionary in  photosArray[0..<min(photosArray.count,21)]{
                        if let photoTitle = photoDictionary["title"] as? String, /* non-fatal */
                               imageUrlString = photoDictionary["url_m"] as? String,
                               imageURL = NSURL(string: imageUrlString),
                               id = photoDictionary["id"] as? String{

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
                                
                                
                        }
                    }
                    CoreDataStackManager.sharedInstance().saveContext()
                    print(self.pin?.photos.count)
                    self.collectionView.reloadData()
                })
                
                
            }
        }
        task.resume()
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

    /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject]) {
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        print(urlString)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                dispatch_async(dispatch_get_main_queue(), {
                 //   self.setUIEnabled(enabled: true)
                })
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                dispatch_async(dispatch_get_main_queue(), {
                //    self.setUIEnabled(enabled: true)
                })
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                dispatch_async(dispatch_get_main_queue(), {
               //     self.setUIEnabled(enabled: true)
                })
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                dispatch_async(dispatch_get_main_queue(), {
                 //   self.setUIEnabled(enabled: true)
                })
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                dispatch_async(dispatch_get_main_queue(), {
//                    self.setUIEnabled(enabled: true)
                })
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                dispatch_async(dispatch_get_main_queue(), {
                 //   self.setUIEnabled(enabled: true)
                })
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary["pages"] as? Int else {
                dispatch_async(dispatch_get_main_queue(), {
                  //  self.setUIEnabled(enabled: true)
                })
                print("Cannot find key 'pages' in \(photosDictionary)")
                return
            }
            
            /* Pick a random page! */
//            let pageLimit = min(totalPages, 40)
//            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            
            self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: 1)
        }
        
        task.resume()
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