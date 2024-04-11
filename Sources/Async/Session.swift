// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation
#if canImport(OSLog)
import OSLog
#endif

open class Session<CL: Client> {
    public var debug = false

    public var urlSession: URLSession
    public let client: CL

    public init(
        with client: CL,
        using urlSession: URLSession = URLSession.shared
    ) {
        self.client = client
        self.urlSession = urlSession
    }

    @discardableResult
    open func dataTask<C: Call>(for call: C) async throws -> (C.Parser.OutputType, HTTPURLResponse) {
        let urlRequest = try await client.encode(call: call)

        let (data, response) = try await urlSession.data(for: urlRequest)

        if debug {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *) {
                Logger.default.debug("\(urlRequest.cURLRepresentation)")
            } else {
                os_log("%s", log: .default, type: .debug, urlRequest.cURLRepresentation)
            }
        }

        guard let response = response as? HTTPURLResponse else {
            throw EndpointsError(
                error: EndpointsParsingError.invalidData(
                    description: "Response was not a valid HTTPURLResponse"
                ),
                response: nil
            )
        }

        do {
            try await call.validate(response: response, data: data) // request-specific validation
            try await client.validate(response: response, data: data) // global validation

            let value = try await client.parse(response: response, data: data, for: call)
            return (value, response)
        } catch {
            throw EndpointsError(error: error, response: response)
        }
    }
}
