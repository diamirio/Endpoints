# Testing

Look at `Tests/` in this repo (`ClientTests`, `RequestTests`, `MultipartTests`, `Tests/Utils/ClientTester.swift`, `FakeHTTPURLResponse`) for the conventions used here, and copy their style.

## Without network

- **Request encoding**: `try await client.encode(call: call)` and assert on `URLRequest` (`url`, `httpMethod`, `allHTTPHeaderFields`, `httpBody`). No `Session` needed.
- **Parsing / validation**: call `client.validate(response:data:)` and `client.parse(response:data:for:)` with a fake `HTTPURLResponse` and fixture `Data`.
- **End to end**: pass a `URLSession` with a `URLProtocol` stub to `Session(with:using:)`.

```swift
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [StubURLProtocol.self]   // your stub
let session = Session(with: client, using: URLSession(configuration: config))
```

## What to cover

- Error mapping: non-2xx → expected domain error, including the `EndpointsError` wrapping (unwrap until the underlying error).
- Auth: header present, refresh failure surfaces your error type from `encode` (not wrapped).
- Parsers: date formats, empty body with `NoContentParser`, missing headers.
