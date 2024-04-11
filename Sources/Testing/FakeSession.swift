// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation
import OSLog

public class FakeSession<CL: Client>: Session<CL> {
    var resultProvider: FakeResultProvider

    public init(with client: CL, resultProvider: FakeResultProvider) {
        self.resultProvider = resultProvider

        super.init(with: client)
    }

    override public func dataTask<C: Call>(
        for call: C
    ) async throws -> (C.Parser.OutputType, HTTPURLResponse) {
        let (response, data) = try await resultProvider.data(for: call)

        if debug {
            if #available(iOS 14.0, *) {
                Logger.default.debug("\(call.request.cURLRepresentation)\n\(response)\n\(response)")
            } else {
                os_log("%s", log: .default, type: .debug, "\(call.request.cURLRepresentation)\n\(response)\n\(response)")
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
