//
//  Extension + MKPlacemark.swift
//  Uber
//
//  Created by Роман Елфимов on 18.08.2021.
//

import UIKit
import MapKit

extension MKPlacemark {
    var address: String? {
        get {
            guard let subThoroughfare = subThoroughfare else { return nil }
            guard let thoroughfare = thoroughfare else { return nil }
            guard let locatlity = locality else { return nil }
            guard let adminArea = administrativeArea else { return nil }
            
            return "\(subThoroughfare) \(thoroughfare), \(locatlity), \(adminArea)"
        }
    }
}
