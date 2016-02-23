
import UIKit
import CoreData
import MapKit


class Pin : NSManagedObject {
    static var count = 0
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
    @NSManaged var id: NSNumber


    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        longitude = dictionary[Keys.Longitude] as! CLLocationDegrees
        latitude = dictionary[Keys.latitude] as! CLLocationDegrees
        Pin.count = Pin.count + 1
        id = Pin.count

    }
    
}


