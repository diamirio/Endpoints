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
        using urlSession: URLSession = URLSession(configuration: .default, delegate: URLSessionDelegateHandler(), delegateQueue: nil)
    ) {
        self.client = client
        self.urlSession = urlSession
    }

    @discardableResult
    open func dataTask<C: Call>(for call: C) async throws -> (C.Parser.OutputType, HTTPURLResponse) {
        let urlRequest = try await client.encode(call: call)

        let (data, response) = try await urlSession.data(for: urlRequest)

        guard let response = response as? HTTPURLResponse else {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *) {
                Logger.default.debug("no response.")
            } else {
                os_log("no response.", log: .default, type: .debug)
            }
            throw EndpointsError(
                error: EndpointsParsingError.invalidData(
                    description: "Response was not a valid HTTPURLResponse"
                ),
                response: nil
            )
        }

        if debug {
            var message = ""
            message += "\(urlRequest.cURLRepresentation)\n"
            message += "\(response.debugDescription)\n"
            message += "\(data.debugDescription(encoding: response.stringEncoding))"

            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *) {
                Logger.default.debug("\(message, privacy: .private)")
            } else {
                os_log("%s", log: .default, type: .debug, message)
            }
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

public class URLSessionDelegateHandler: NSObject, URLSessionTaskDelegate {
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        let message = "\(response.url?.absoluteString ?? "") -> redirected to -> \(request.url?.absoluteString ?? "")"

        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *) {
            Logger.default.debug("\(message, privacy: .private)")
        } else {
            os_log("%s", log: .default, type: .debug, message)
        }

        completionHandler(request)
    }
}
