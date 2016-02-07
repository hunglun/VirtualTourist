//
//  Photo.swift
//  VirtualTourist
//
//  Created by hunglun on 2/2/16.
//  Copyright © 2016 hunglun. All rights reserved.
//
/* 1. Import Core Data
 * 2. Make Person a subclass of NSManagedObject
 * 3. Add @NSManaged in front of each of the properties/attributes
 * 4. Include the standard Core Data init method, which inserts the object into a context
 * 5. Write an init method that takes a dictionary and a context. This the biggest chagne to the class
 */
 
 // 1. Import CoreData
import CoreData
import MapKit

// 2. Make Person a subclass of NSManagedObject
class Photo : NSManagedObject {
    
    struct Keys {
        static let ImagePath =  "imagePath"
        static let ID = "id"
    }
    
    // 3. We are promoting these four from simple properties, to Core Data attributes
    
    @NSManaged var imagePath: String
    @NSManaged var id: String
    @NSManaged var pin: Pin?
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        imagePath = dictionary[Keys.ImagePath] as! String
        id = dictionary[Keys.ID] as! String
        
    }
    
    func getPathForPhotoId(id:String) -> NSURL{
        let filename = "\(id).jpg"
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathArray = [dirPath, filename]
        let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!
        return fileURL
    }

    func loadPhotoFromDisk(id : String)-> NSURL?{
        let photoFileURL = getPathForPhotoId(id)
        if NSFileManager.defaultManager().fileExistsAtPath(photoFileURL.path!) {
            return photoFileURL
        }else{
            return nil
        }
    }
    var image: UIImage? {
        get {
            //        return TheMovieDB.Caches.imageCache.imageWithIdentifier(imagePath)
            if let data = NSData(contentsOfURL:  loadPhotoFromDisk(id)!){
                return UIImage(data: data)
            }
            print("can't find file \(imagePath)")
            return nil
        }
        
        set {
            //      TheMovieDB.Caches.imageCache.storeImage(image, withIdentifier: imagePath!)
        }
    }
}

