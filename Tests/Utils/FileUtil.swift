// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

enum FileUtil {
	/// Loads a file with aa given name and extension located in the same bundle as the `FileUtil` class
	/// - Parameter name: the name of the file
	/// - Parameter ext: the extension (without the `.`)
	/// - Parameter bundle: the bundle where the file is included
	static func load(
		named name: String,
		withExtension ext: String = "json",
		bundle: Bundle = Bundle.module
	) throws -> Data {
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
			"File missing"
		}
	}
}
