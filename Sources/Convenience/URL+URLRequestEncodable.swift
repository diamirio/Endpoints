//
//  URL+URLRequestEncodable.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 27.08.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation

extension URL: URLRequestEncodable {
    public var urlRequest: URLRequest {
        return URLRequest(url: self)
    }
}
