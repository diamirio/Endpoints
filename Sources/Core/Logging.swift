// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation
import OSLog

@available(iOS 14.0, *)
extension Logger {
    static var `default` = Logger(subsystem: "io.diamir.Endpoints", category: "EndpointsSession")
}
