//
//  PWUtils.swift
//  Pods
//
//  Created by Thomas Koller on 04/10/16.
//
//

import Foundation
import HTTPStatusCodes

extension URLResponse {
    public var encoding: String.Encoding {
        var enc = String.Encoding.isoLatin1
        
        if let encodingName = textEncodingName {
            enc = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(encodingName as CFString!)))
        }
        
        return enc
    }
}
extension HTTPStatusCode {
    public var isError : Bool {
        return isClientError || isServerError
    }
    
}
