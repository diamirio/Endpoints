# Client patterns

All examples wrap `DefaultClient` and delegate to it.

## Authenticated client

```swift
struct AuthenticatedClient: Client {
    private let client: DefaultClient
    private let tokenProvider: any TokenProvider   // your type, must be Sendable

    init(url: URL, tokenProvider: any TokenProvider) {
        client = DefaultClient(url: url)
        self.tokenProvider = tokenProvider
    }

    func encode(call: some Call) async throws -> URLRequest {
        var request = try await client.encode(call: call)
        let token = try await tokenProvider.validToken()   // refresh logic lives here, not in Endpoints
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    func parse<C: Call>(
        response: HTTPURLResponse?,
        data: Data?,
        for call: C
    ) async throws -> C.Parser.OutputType {
        try await client.parse(response: response, data: data, for: call)
    }

    func validate(response: HTTPURLResponse?, data: Data?) async throws {
        try await client.validate(response: response, data: data)
    }
}
```

- Errors thrown from `encode` are not wrapped in `EndpointsError`; give them a type your API boundary recognizes.
- Resolve the credential per request. If the token can change while requests are in flight, keep the credential captured for that request instead of mutating a shared header dictionary.
- Never log tokens. `Session(debug: true)` logs the full cURL including `Authorization`.
- `BasicAuthorization(user:password:).header` gives a ready `Authorization` header for Basic auth.

## Mapping backend errors

```swift
func parse<C: Call>(
    response: HTTPURLResponse?,
    data: Data?,
    for call: C
) async throws -> C.Parser.OutputType {
    do {
        return try await client.parse(response: response, data: data, for: call)
    } catch {
        guard let response, let data,
              let apiError = try? JSONDecoder().decode(ApiErrorBody.self, from: data)
        else { throw error }
        throw StatusCodeError.unacceptable(code: response.statusCode, reason: apiError.message)
    }
}
```

Note that non-2xx responses normally fail in `validate` (before `parse`), so to map error bodies of failed requests, do it in `validate`:

```swift
func validate(response: HTTPURLResponse?, data: Data?) async throws {
    do {
        try await client.validate(response: response, data: data)
    } catch {
        if let response, let data, let body = try? JSONDecoder().decode(ApiErrorBody.self, from: data) {
            throw StatusCodeError.unacceptable(code: response.statusCode, reason: body.message)
        }
        throw error
    }
}
```

## Custom status handling

`StatusCodeValidator` accepts 200..<300. For other rules (maintenance 503, expected 404) implement `validate` in the Client (API-wide) or the Call (endpoint-specific, runs first).

## Several backends

One `Client` and one `Session` per backend/base URL. Share the underlying `URLSession` by passing it to `Session(with:using:)` if the connection pool should be shared.
