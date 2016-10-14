//
//  PWHTTPError.swift
//  Pods
//
//  Created by Thomas Koller on 04/10/16.
//
//

import Foundation

enum PWHTTPError: Error {
    case parsingError(description: String)
    case serverError(description: String)
}
