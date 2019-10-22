//
//  HTTPBinModel.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 04.09.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation
import Endpoints

/// A basic model for a HTTPBin response (only contains atm needed fields
struct HTTPBinResponse: Decodable {
    let files: [String: String]
    let form: [String: String]
    let headers: [String: String]
}
