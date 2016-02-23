//
//  Photo.swift
//  VirtualTourist
//
//  Created by hunglun on 2/2/16.
//  Copyright © 2016 hunglun. All rights reserved.
//

import CoreData
import MapKit

class Photo : NSManagedObject {
    
    struct Keys {
        static let ImagePath =  "imagePath"
        static let ID = "id"
        static let Marked = "marked"
    }
    
    
    @NSManaged var imagePath: String
    @NSManaged var id: String
    @NSManaged var pin: Pin?
    @NSManaged var marked: Bool
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        imagePath = dictionary[Keys.ImagePath] as! String
        id = dictionary[Keys.ID] as! String
        marked = false
        
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
    func deleteImage(){
        let photoFileURL = getPathForPhotoId(id)
        if NSFileManager.defaultManager().fileExistsAtPath(photoFileURL.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(photoFileURL.path!)
            } catch _ {
                print("Error removing file \(photoFileURL.path)")
            }
        }

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
            var imageData : NSData?
            if let localURL = self.loadPhotoFromDisk(id) {
                imageData = NSData(contentsOfURL: localURL)
                print("found \(localURL.path)")
                
            }else {
                dispatch_async(dispatch_get_main_queue(), {
                    imageData = NSData(contentsOfURL: NSURL(string: self.imagePath)!)
                    self.savePhotoToDisk(self.id ,data: imageData!)
                })
            }
            

            if let data = NSData(contentsOfURL:  getPathForPhotoId(id)){
                return UIImage(data: data)
            }
            print("can't find file \(imagePath)")
            return nil
        }
        
        set {
        }
    }
    
    func getImage(collectionView : UICollectionView)-> UIImage? {
        var imageData : NSData?
        if let localURL = self.loadPhotoFromDisk(id) {
            imageData = NSData(contentsOfURL: localURL)
            print("Found \(localURL.path)")
            
        }else {
            dispatch_async(dispatch_get_main_queue(), {
                imageData = NSData(contentsOfURL: NSURL(string: self.imagePath)!)
                self.savePhotoToDisk(self.id ,data: imageData!)
                print("Downloaded \(self.imagePath)")
                collectionView.reloadData()
            })
        }
        if let data = NSData(contentsOfURL:  getPathForPhotoId(id)){
            return UIImage(data: data)
           
        }
        print("Pending \(imagePath)")
        return nil
    }
}


