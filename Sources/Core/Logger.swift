// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation
#if canImport(OSLog)
    import OSLog
#endif

#if canImport(OSLog)
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
    extension Logger {
        static var `default` = Logger(subsystem: "io.diamir.Endpoints", category: "EndpointsSession")
    }
#endif
