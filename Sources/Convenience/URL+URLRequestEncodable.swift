// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

extension URL: URLRequestEncodable {
    public var urlRequest: URLRequest {
        return URLRequest(url: self)
    }
}
