<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/diamirio/AsyncReactor/assets/19715246/56eef378-e63e-4732-8710-040d3440afbb">
  <img alt="DIAMIR Logo" src="https://github.com/diamirio/AsyncReactor/assets/19715246/8424fef3-5aeb-4e15-af36-55f1f3fc37b0">
</picture>

# Endpoints

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

Endpoints makes it easy to write a type-safe network abstraction layer for any Web-API.

It requires Swift 6.2+, makes heavy use of generics and protocols (with protocol extensions). It also encourages a clean separation of concerns and the use of value types (i.e. structs). Built for modern Swift concurrency with async/await and actor support.

**Key Features:**
- **Type-safe API**: Strongly typed requests and responses
- **Swift 6.2+**: Full support for Swift's strict concurrency model
- **Actor-based Session**: Thread-safe networking with `Session` as an actor
- **Sendable conformance**: All core protocols require `Sendable` conformance for safe concurrent access
- **Async/await**: Native async/await support throughout the API
- **Flexible parsing**: Multiple built-in response parsers with support for custom parsers
- **JSON Codable**: First-class support for `Codable` types

## Requirements

* Swift 6.2+
* iOS 13+
* tvOS 12+
* macOS 10.15+
* watchOS 6+
* visionOS 1+

## Installation

**Swift Package Manager:**

```swift
.package(url: "https://github.com/diamirio/Endpoints.git", .upToNextMajor(from: "3.0.0"))
```

## Usage

### Basics

Here's how to load a random image from Giphy.

```swift
// A client is responsible for encoding and parsing all calls for a given Web-API.
let client = AnyClient(baseURL: URL(string: "https://api.giphy.com/v1/")!)

// A call encapsulates the request that is sent to the server and the type that is expected in the response.
let call = AnyCall<DataResponseParser>(Request(.get, "gifs/random", query: ["tag": "cat", "api_key": "dc6zaTOxFJmzC"]))

// A session is an actor that wraps `URLSession` and allows you to start the request for the call and get the parsed response object (or an error).
// Session is an actor, ensuring thread-safe access to URLSession.
let session = Session(with: client)

// start call
let (body, httpResponse) = try await session.dataTask(for: call)
```

### Response Parsing

A call is supposed to know exactly what response to expect from its request. It delegates the parsing of the response to a `ResponseParser`.

Some built-in types already adopt the `ResponseParser` protocol (using protocol extensions), so you can for example turn any response into a JSON array or dictionary:

```swift
// Replace `DataResponseParser` with any `ResponseParser` implementation
let call = AnyCall<DictionaryParser<String, Any>>(Request(.get, "gifs/random", query: ["tag": "cat", "api_key": "dc6zaTOxFJmzC"]))

...

// body is now a JSON dictionary 🎉
let (body, httpResponse) = try await session.dataTask(for: call)
````

```swift
let call = AnyCall<JSONParser<GiphyGif>>(Request(.get, "gifs/random", query: ["tag": "cat", "api_key": "dc6zaTOxFJmzC"]))

...

// body is now a `GiphyGif` dictionary 🎉
let (body, httpResponse) = try await session.dataTask(for: call)
```

#### Provided `ResponseParser`s

Look up the documentation in the code for further explanations of the types.

* `DataResponseParser`
* `DictionaryParser`
* `JSONParser`
* `NoContentParser`
* `StringConvertibleParser`
* `StringParser`

#### JSON Codable Integration

`Endpoints` has a built in JSON Codable support.

##### Decoding

The `ResponseParser` responsible for handling decodable types is the `JSONParser`.
The `JSONParser` uses the default `JSONDecoder()` by default, but you can customize it by creating a custom parser with a configured decoder.

```swift
// Decode a type using the default decoder
struct GiphyCall: Call {
    typealias Parser = JSONParser<GiphyGif>
    ...
}

// Custom parser with configured decoder
// Note: T must be Sendable for Swift 6.2+ concurrency safety
struct CustomJSONParser<T: Decodable & Sendable>: ResponseParser {
    typealias OutputType = T

    let jsonDecoder: JSONDecoder

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.jsonDecoder = decoder
    }

    func parse(data: Data, encoding: String.Encoding) throws -> T {
        try jsonDecoder.decode(T.self, from: data)
    }
}

struct GiphyCall: Call {
    typealias Parser = CustomJSONParser<GiphyGif>
    ...
}
```

##### Encoding

Every encodable is able to provide a `JSONEncoder()` to encode itself via the `toJSON()` method.

### Dedicated Calls

`AnyCall` is the default implementation of the `Call` protocol, which you can use as-is. But if you want to make your networking layer really type-safe you'll want to create a dedicated `Call` type for each operation of your Web-API.

**Note:** All `Call` types must conform to `Sendable` for Swift 6.2+ concurrency safety. Use value types (structs) with sendable properties:

```swift
struct GetRandomImage: Call {
    typealias Parser = DictionaryParser<String, Any>

    var tag: String

    var request: URLRequestEncodable {
        return Request(.get, "gifs/random", query: [ "tag": tag, "api_key": "dc6zaTOxFJmzC" ])
    }
}

// `GetRandomImage` is much safer and easier to use than `AnyCall`
let call = GetRandomImage(tag: "cat")
```

### Dedicated Clients

A client is responsible for handling things that are common for all operations of a given Web-API. Typically this includes appending API tokens or authentication tokens to a request or validating responses and handling errors.

`AnyClient` is the default implementation of the `Client` protocol and can be used as-is or as a starting point for your own dedicated client.

You'll usually need to create your own dedicated client that implements the `Client` protocol and delegates the encoding of requests and parsing of responses to an `AnyClient` instance, as done here.

**Note:** All `Client` types must conform to `Sendable`. Use structs with sendable properties to ensure thread-safety:

```swift
struct GiphyClient: Client {
    var client: Client
    var apiKey = "dc6zaTOxFJmzC"

    init() {
        let url = URL(string: "https://api.giphy.com/v1/")!
        self.client = AnyClient(baseURL: url)
    }

    func encode(call: some Call) async throws -> URLRequest {
        var request = try await client.encode(call: call)

        // Append the API key to every request
        request.append(query: ["api_key": apiKey])

        return request
    }

    func parse<C>(response: HTTPURLResponse?, data: Data?, for call: C) async throws -> C.Parser.OutputType
        where C: Call {
        do {
            // Use `AnyClient` to parse the response
            // If this fails, try to read error details from response body
            return try await client.parse(response: response, data: data, for: call)
        } catch {
            // See if the backend sent detailed error information
            guard
                let response,
                let data,
                let errorDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let meta = errorDict?["meta"] as? [String: Any],
                let errorCode = meta["error_code"] as? String
            else {
                // no error info from backend -> rethrow default error
                throw error
            }

            // Propagate error that contains errorCode as reason from backend
            throw StatusCodeError.unacceptable(code: response.statusCode, reason: errorCode)
        }
    }
}
```

### Dedicated Response Types

You usually want your networking layer to provide a dedicated response type for every supported call. In our example this could look  like this:

```swift
struct RandomImage: Decodable {
    struct Data: Decodable {
        let url: URL
        
        private enum CodingKeys: String, CodingKey {
            case url = "image_url"
        }
    }
    
    let data: Data
}

struct GetRandomImage: Call {
    typealias Parser = JSONParser<RandomImage>
    ...
}
```

### Type-Safety

With all the parts in place, users of your networking layer can now perform type-safe requests and get a type-safe response with a few lines of code:

```swift
let client = GiphyClient()
let call = GetRandomImage(tag: "cat")
let session = Session(with: client)

let (body, response) = try await session.dataTask(for: call)
print("image url: \(body.data.url)")
```

## Example

Example implementation can be found [here](https://github.com/diamirio/Endpoints-Example).
