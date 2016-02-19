//
//  Flickr.swift
//  Flickr
//
//  Created by Hung Lun on 15/Feb/16.
//

import Foundation

let _BASE_URL = "https://api.flickr.com/services/rest/"
let _METHOD_NAME = "flickr.photos.search"
let _API_KEY = "8ba389c3eed8a5d6329c57c0f20ef23b"
let _EXTRAS = "url_m"
let _SAFE_SEARCH = "1"
let _DATA_FORMAT = "json"
let _NO_JSON_CALLBACK = "1"
let _PER_PAGE = "21"
class Flickr : NSObject {
    
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    var session: NSURLSession
    
    
    static var longitude : Double!
    static var latitude : Double!
    static var page : Int!
    
    class func createBoundingBoxString() -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude! - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude! - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude! + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude! + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    

  
    var methodArguments = [
        "method": _METHOD_NAME,
        "api_key": _API_KEY,
        "bbox": "",
        "safe_search": _SAFE_SEARCH,
        "extras": _EXTRAS,
        "format": _DATA_FORMAT,
        "nojsoncallback": _NO_JSON_CALLBACK,
        "per_page": _PER_PAGE
    ]
    
   
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
        methodArguments["bbox"] = Flickr.createBoundingBoxString()
    }
    
    
    // MARK: - All purpose task method for data
    
 
    
    // MARK: Flickr API

    
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int,completionHandler: CompletionHander) -> NSURLSessionDataTask  {
        
        /* Add the page to the method's arguments */
        self.methodArguments["bbox"] = Flickr.createBoundingBoxString()

        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()

        let urlString = _BASE_URL + Flickr.escapedParameters(withPageDictionary)
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
      
                for photoDictionary in  photosArray[0..<min(photosArray.count,21)]{
                    completionHandler(result: photoDictionary,error: nil)
                }
                
               /* dispatch_async(dispatch_get_main_queue(), {
                    for photoDictionary in  photosArray[0..<min(photosArray.count,21)]{
                        completionHandler(result: photoDictionary,error: nil)
                    }
                    
                })
                */
                
            }
        }
        task.resume()
        return task
    }

    /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
    func getImageFromFlickrBySearch(downloadCompletionHandler :CompletionHander) {

        let session = NSURLSession.sharedSession()
        self.methodArguments["bbox"] = Flickr.createBoundingBoxString()
        let urlString = _BASE_URL + Flickr.escapedParameters(methodArguments)
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

            let p = Flickr.page % (totalPages + 1)
            print("Page: \(p)")
            self.getImageFromFlickrBySearchWithPage(self.methodArguments,
                                                    pageNumber: p,
                                                    completionHandler: downloadCompletionHandler)
            
        }
        
        task.resume()
    }
    // Parsing the JSON
 

    // URL Encoding a dictionary into a parameter string
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> Flickr {
        
        struct Singleton {
            static var sharedInstance = Flickr()
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Date Formatter
    
    class var sharedDateFormatter: NSDateFormatter  {
        
        struct Singleton {
            static let dateFormatter = Singleton.generateDateFormatter()
            
            static func generateDateFormatter() -> NSDateFormatter {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-mm-dd"
                
                return formatter
            }
        }
        
        return Singleton.dateFormatter
    }
    
}