// Copyright © 2023 DIAMIR. All Rights Reserved.

import Endpoints
import Foundation

/// A basic model for a HTTPBin response (only contains atm needed fields
struct HTTPBinResponse: Decodable {
	let files: [String: String]
	let form: [String: String]
	let headers: [String: String]
}
