# Testing

Use Swift Testing. In an app project, follow the project's test conventions (or the `ios-tests` skill if it is available); this reference only covers how to drive Endpoints. When working on Endpoints itself, follow the style of this repo's `Tests/` (`ClientTests`, `RequestTests`, `MultipartTests`, `Tests/Utils/ClientTester.swift`, `FakeHTTPURLResponse`).

## Without network

- **Request encoding**: `try await client.encode(call: call)` and assert on `URLRequest` (`url`, `httpMethod`, `allHTTPHeaderFields`, `httpBody`). No `Session` needed.
- **Parsing / validation**: call `client.validate(response:data:)` and `client.parse(response:data:for:)` with a fake `HTTPURLResponse` and fixture `Data`.
- **End to end**: pass a `URLSession` with a `URLProtocol` stub to `Session(with:using:)`.

```swift
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [StubURLProtocol.self]   // your stub
let session = Session(with: client, using: URLSession(configuration: config))
```

## Example

```swift
import Endpoints
import Foundation
import Testing
@testable import MyApp

struct GetUserTests {
    let client = DefaultClient(url: URL(string: "https://api.example.com/v1/")!)

    @Test("Encodes a GET to the user path")
    func encodesRequest() async throws {
        // Given
        let sut = GetUser(id: 1)

        // When
        let request = try await client.encode(call: sut)

        // Then
        #expect(request.url?.absoluteString == "https://api.example.com/v1/users/1")
        #expect(request.httpMethod == "GET")
    }

    @Test("Parses the user from the response body")
    func parsesUser() async throws {
        // Given
        let sut = GetUser(id: 1)
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com/v1/users/1")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let data = Data(#"{"id": 1, "name": "Ann"}"#.utf8)

        // When
        let user = try await client.parse(response: response, data: data, for: sut)

        // Then
        #expect(user == User(id: 1, name: "Ann"))
    }
}
```

## What to cover

- Error mapping: non-2xx → expected domain error, including the `EndpointsError` wrapping (unwrap until the underlying error).
- Auth: header present, refresh failure surfaces your error type from `encode` (not wrapped).
- Parsers: date formats, empty body with `NoContentParser`, missing headers.
