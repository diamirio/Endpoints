---
name: endpoints
description: Build a type-safe Web-API layer with diamirio/Endpoints 4.x — dedicated Calls, Clients and ResponseParsers, request bodies (JSON, form, multipart), the actor-based Session, validation, error handling and testing. Use when a project imports Endpoints or adds it as a dependency, when writing or reviewing a Call, Client, ResponseParser or Body, when handling EndpointsError or StatusCodeError, when adding auth headers or token handling to a Client, or when migrating from Endpoints 1.x-3.x (AnyClient, callback-based Session) to 4.x.
---

# Endpoints

Endpoints (Swift 6.2+, `Sendable` throughout, `async`/`await`) separates a Web-API layer into small value types. Use it by filling in the extension points below — do not wrap `Session` in another networking layer.

Source of truth is the installed package (`Sources/Core`, `Sources/Async`, `Sources/Parsing`, `Sources/Body`, `Sources/Error`) and the [README](../../../README.md). Read those before assuming an API; this skill only summarizes how the pieces fit.

## References

Load only what the task needs:

- `references/client-patterns.md` — dedicated clients: auth headers, per-request credentials, error mapping, custom validation.
- `references/parsers-and-bodies.md` — custom `ResponseParser`s (headers, files, dates), body types, query/header rules.
- `references/testing.md` — testing Calls and Clients without network.
- `Migration/V4_0_0.md` — upgrading from 3.x.

## The pieces

| Type | Responsibility |
|---|---|
| `Call` | One endpoint: `request` (method, path, query, header, body) and `Parser`. |
| `ResponseParser` | Turns the response into the call's output type. |
| `Client` | Everything common to the API: `encode` (base URL, auth), `validate`, `parse`. |
| `Session<CL: Client>` | Actor that runs a call: `try await session.dataTask(for: call)` → `(body, HTTPURLResponse)`. |
| `Body` | Request payload plus its `Content-Type` header. |

Application code owns what Endpoints does not do: login, token refresh, credential storage, retries, caching.

## Minimal flow

```swift
struct GetUser: Call {
    typealias Parser = JSONParser<User>

    let id: Int

    var request: URLRequestEncodable {
        Request(.get, "users/\(id)")
    }
}

let session = Session(with: DefaultClient(url: URL(string: "https://api.example.com/v1/")!))
let (user, response) = try await session.dataTask(for: GetUser(id: 1))
```

- Relative paths are resolved against the client's URL by `DefaultClient.encode`; absolute URLs in a `Request` are left as they are.
- `dataTask(for:)` is `@discardableResult`.
- `Session(with:debug: true)` logs cURL, response and body (privacy `.private`). Never enable it for calls carrying secrets in release builds.

## Rules for Calls

- One `struct` per operation, named after it. Properties must be `Sendable`.
- Declare only `Parser` and `request`. Do not put base URLs, auth or shared headers in a Call; that belongs to the Client.
- Use `Request(.post, "path", query: [...], header: [...], body: ...)`. `query` and `header` are `[String: String]`; a request header overrides a body header.
- `AnyCall<Parser>` is for one-off or dynamic requests; prefer a dedicated Call for anything reused.
- Override `validate(response:data:)` on a Call only for rules specific to that endpoint.

## Parsers

Built in: `JSONParser<T>`, `DictionaryParser`, `DataResponseParser`, `StringParser`, `NoContentParser`, `StringConvertibleParser` (`BoolParser`, `IntParser`, `DoubleParser`, `FloatParser`).

- `JSONParser` decodes with `.iso8601` dates and `.convertFromSnakeCase`. Different strategy (fractional seconds, epoch, camelCase) → write a small custom parser with its own `JSONDecoder`; do not patch DTOs with custom `init(from:)` or String→Date helpers.
- DTOs are plain `Decodable & Sendable` structs.
- A parser that needs headers overrides `parse(response:data:)`; `parse(data:encoding:)` is still required — make it throw `EndpointsParsingError.invalidData` if it cannot work without headers.
- Empty responses (204): use `NoContentParser`.

## Clients

- Wrap a `DefaultClient` and delegate to it; add behavior around it.
- `encode(call:)` — add auth and API-wide headers after `DefaultClient.encode`.
- `validate` — call `DefaultClient.validate` first (status code must be 2xx), then add API-wide rules.
- `parse` — delegate, and optionally map backend error bodies to your own error.
- `Client` must be `Sendable`: use structs with `Sendable` stored properties.

See `references/client-patterns.md` for auth and error-mapping patterns.

## Execution order and errors

`Session.dataTask(for:)` runs:

1. `client.encode(call:)` — errors here are **not** wrapped.
2. `URLSession.data(for:)` — transport errors are **not** wrapped.
3. `call.validate` → `client.validate` → `client.parse` — any error here is wrapped into `EndpointsError(error:response:)`.

Consequences:

- `Call.validate` runs **before** `Client.validate`; a Call that throws early bypasses Client validation and parsing.
- `DefaultClient.validate` (via `StatusCodeValidator`) already throws an `EndpointsError` wrapping `StatusCodeError.unacceptable`, and `Session` wraps once more. When inspecting errors, unwrap `EndpointsError` repeatedly until you reach the underlying error; read `response` from whichever layer has it.
- Handle errors at the API boundary and expose domain errors to features; do not make every view model pattern-match `EndpointsError`.

## Dos and don'ts

- Do keep one `Session` per `Client` and reuse it; `Session` is an actor and thread-safe.
- Do resolve credentials per request in `encode`; do not mutate shared auth state on a long-lived Client.
- Don't claim Endpoints handles token refresh, 401 logout, retries or caching — it does not.
- Don't use 3.x APIs (`AnyClient`, completion-handler `Session`); in 4.x use `DefaultClient` and `async` calls.
- Don't add a parallel `URLSession` layer for the same backend.

## Checklist: adding an endpoint

1. Create the DTO (`Decodable & Sendable`).
2. Create the `Call` with `Parser` and `request`.
3. If the response is not plain JSON, add or reuse a `ResponseParser`.
4. Run it through the app's existing `Session`; map errors at the API boundary.
5. Add a test with a fake response (`references/testing.md`).
