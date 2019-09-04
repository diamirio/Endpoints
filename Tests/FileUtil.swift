//
//  FileUtil.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 04.09.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation

class FileUtil {

    /// Loads a file with aa given name and extension located in the same bundle as the `FileUtil` class
    /// - Parameter name: the name of the file
    /// - Parameter ext: the extension (without the `.`)
    /// - Parameter bundle: the bundle where the file is included
    static func load(
        named name: String,
        withExtension ext: String,
        bundle: Bundle = Bundle(for: FileUtil.self)
    ) throws -> Data {
        let bundle = Bundle(for: FileUtil.self)

        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw FileError.missing
        }

        return try Data(contentsOf: url)
    }
}

enum FileError: LocalizedError {
    case missing

    var errorDescription: String? {
        switch self {
        case .missing:
            return "File missing"
        }
    }
}
