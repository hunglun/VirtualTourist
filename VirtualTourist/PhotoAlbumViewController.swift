//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by hunglun on 1/26/16.
//  Copyright © 2016 hunglun. All rights reserved.
//


import UIKit
class PhotoAlbumViewController : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        populateNavigationBar()
    }

    func populateNavigationBar() {
        
        navigationItem.leftBarButtonItem  = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "backToMapView")

    }
    
    func backToMapView(){
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
}