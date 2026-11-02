# Parsers and bodies

## Custom JSON parser

`JSONParser` is `.iso8601` + `.convertFromSnakeCase`. For anything else:

```swift
struct EpochJSONParser<T: Decodable & Sendable>: ResponseParser {
    typealias OutputType = T

    private let decoder: JSONDecoder

    init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .useDefaultKeys
    }

    func parse(data: Data, encoding: String.Encoding) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}
```

`ResponseParser` requires `init()` (via `DataParser`); `Client.parse` constructs the parser with `C.Parser()`, so a parser cannot take constructor arguments. Put configuration inside `init()`.

For ISO dates with fractional seconds, use `.custom` with `ISO8601DateFormatter` options; `.iso8601` does not parse them.

## Parser that needs response headers (file download)

```swift
struct FileParser: ResponseParser {
    typealias OutputType = DownloadedFile

    func parse(response: HTTPURLResponse, data: Data) throws -> DownloadedFile {
        DownloadedFile(name: response.suggestedFilename ?? "file", mimeType: response.mimeType, data: data)
    }

    // Required by DataParser; Client.parse always calls the response overload above.
    func parse(data: Data, encoding: String.Encoding) throws -> DownloadedFile {
        throw EndpointsParsingError.invalidData(description: "FileParser needs response headers")
    }
}
```

`DownloadedFile` must be `Sendable`.

## Bodies

| Body | Use | Content-Type |
|---|---|---|
| `JSONEncodedBody(encodable:)` | `Encodable` model | `application/json` |
| `JSONEncodedBody(jsonObject:)` | dictionary / array | `application/json` |
| `FormEncodedBody(parameters:)` | login-style forms | `application/x-www-form-urlencoded` |
| `MultipartBody(parts:)` | uploads | `multipart/form-data; boundary=…` |
| `Data`, `String` | raw payload | none — set the header yourself |

- Both `JSONEncodedBody` inits `throw`; the `Call.request` getter is non-throwing, so encode in the Call's initializer or build the body with a custom `Body` type.
- `Encodable.toJSON()` uses a plain `JSONEncoder()`; override `static var jsonEncoder` on a type if it needs other strategies.
- A custom `Body` implements `requestData` and optionally `header`:

```swift
struct ExportBody: Body {
    let format: String

    var header: Parameters? { ["Content-Type": "application/json"] }
    var requestData: Data { (try? JSONEncoder().encode(["format": format])) ?? Data() }
}
```

## Query and headers

- `Request(.get, "path", query: ["a": "b"])` percent-encodes query items via `URLComponents`. Dictionary order is not stable; do not rely on parameter order.
- Per-request headers go in `header:`. Common headers belong in `Client.encode`.
