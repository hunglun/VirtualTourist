
import UIKit

/**
 * Person.swift
 *
 * Person is a subclass of NSManagedObject. You will be modifying the Person class in the
 * "Plain Favorite Actors" Project so that it matches this file.
 *
 * There are 5 changes to be made. They are listed below, and called out in comments in the
 * code.
 *
 * 1. Import Core Data
 * 2. Make Person a subclass of NSManagedObject
 * 3. Add @NSManaged in front of each of the properties/attributes
 * 4. Include the standard Core Data init method, which inserts the object into a context
 * 5. Write an init method that takes a dictionary and a context. This the biggest chagne to the class
 */
 
 // 1. Import CoreData
import CoreData
import MapKit

// 2. Make Person a subclass of NSManagedObject
class Pin : NSManagedObject {
    
    struct Keys {
        static let latitude =  "latitude"
        static let Longitude = "longitude"
        static let Photos = "photos"
        static let ID = "id"
    }
    
    // 3. We are promoting these four from simple properties, to Core Data attributes
    @NSManaged var photos: [Photo]
    @NSManaged var longitude: CLLocationDegrees
    @NSManaged var latitude: CLLocationDegrees

//    @NSManaged var id: NSNumber
//    @NSManaged var movies: [Movie]

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        longitude = dictionary[Keys.Longitude] as! CLLocationDegrees
        latitude = dictionary[Keys.latitude] as! CLLocationDegrees
//        id = dictionary[Keys.ID] as! Int

    }
    
    var image: UIImage? {
        get {
    //        return TheMovieDB.Caches.imageCache.imageWithIdentifier(imagePath)
            return nil
        }
        
        set {
      //      TheMovieDB.Caches.imageCache.storeImage(image, withIdentifier: imagePath!)
        }
    }
}


