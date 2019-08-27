//
//  BasicAuthorization.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 27.08.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation

public struct BasicAuthorization {
    public let user: String
    public let password: String

    public init(user: String, password: String) {
        self.user = user
        self.password = password
    }

    public var key: String {
        return "Authorization"
    }

    public var value: String {
        var value = "\(user):\(password)"
        let data = value.data(using: .utf8)!

        value = data.base64EncodedString(options: .endLineWithLineFeed)

        return "Basic \(value)"
    }

    public var header: Parameters {
        return [ key: value ]
    }
}

