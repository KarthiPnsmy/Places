//
//  Util.swift
//  Places
//
//  Created by Karthi Ponnusamy on 15/4/17.
//  Copyright © 2017 Karthi Ponnusamy. All rights reserved.
//

import Foundation

class Util{
    static func formatDistanceText(distanceinKiloMeter: Double) -> String{
        return "\(String(format:"%.1f", distanceinKiloMeter)) km"
    }
}
