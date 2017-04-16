//
//  Place.swift
//  Places
//
//  Created by Karthi Ponnusamy on 1/4/17.
//  Copyright © 2017 Karthi Ponnusamy. All rights reserved.
//

import MapKit

class Place: NSObject, MKAnnotation{
    var name: String
    var place_id: String
    var rating: Double?
    var vicinity: String?
    var open_now:Bool?
    var coordinate: CLLocationCoordinate2D
    var phone_number: String?
    var timings: [String]?
    var photos: [String]?
    var reviews: [Review]?
    var distance: Double?
    
    init(name: String, place_id: String, locationCoordinate:CLLocationCoordinate2D) {
        
        self.name = name
        self.place_id = place_id
        self.coordinate = locationCoordinate
    }
    
    var subtitle: String? {
        return vicinity
    }
    
    var title: String? {
        if name.isEmpty {
            return "(No Title)"
        } else {
            return name
        }
    }
}
