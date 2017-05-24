[![Build Status](https://travis-ci.org/tailoredmedia/Endpoints.svg?branch=master)](https://travis-ci.org/tailoredmedia/Endpoints)
	[![codecov](https://codecov.io/gh/tailoredmedia/Endpoints/branch/master/graph/badge.svg)](https://codecov.io/gh/tailoredmedia/Endpoints)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Endpoints.svg)](https://cocoapods.org/pods/Endpoints)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/cocoapods/p/Endpoints.svg)](http://cocoadocs.org/docsets/Endpoints)

# Endpoints

Endpoints makes it easy to write a type-safe network abstraction layer for any Web-API.

It requires Swift 3, makes heavy use of generics (and generalized existentials) and protocols (and protocol extensions). It also encourages a clean separation of concerns and the use of value types (i.e. structs).

## Usage

### Basics

Here's how to load a random image from Giphy.

```swift
// A client is responsible for encoding and decoding all calls for a given Web-API.
let client = AnyClient(baseURL: URL(string: "https://api.giphy.com/v1/")!)

// A call encapsulates the request that is sent to the server and the type that is expected in the response.
let call = AnyCall<Data>(Request(.get, "gifs/random", query: [ "tag": "cat", "api_key": "dc6zaTOxFJmzC" ]))

// A session wraps `URLSession` and allows you to start the request for the call and get the decoded response object (or an error) in a completion block.
let session = Session(with: client)

// enable debug-mode to log network traffic
session.debug = true

// start call
session.start(call: call) { result in
    result.onSuccess { value in
        //value is an object of the type specified in `Call`
    }.onError { error in
        //something went wrong
    }
}
```

### Response Decoding

A call is supposed to know exactly what response to expect from its request. It delegates the decoding of the response to a `ResponseDecoder`.

Some built-in types already adopt the `ResponseDecoder` protocol (using protocol extensions), so you can for example turn any response into a JSON array or dictionary:

```swift
// Replace `Data` with any `ResponseDecoder` implementation
let call = AnyCall<[String: Any]>(Request(.get, "gifs/random", query: [ "tag": "cat", "api_key": "dc6zaTOxFJmzC" ]))
...
session.start(call: call) { result in
    result.onSuccess { value in
        //value is now a JSON dictionary 🎉
    }
}
```

### Dedicated Calls

`AnyCall` is the default implementation of the `Call` protocol, which you can use as-is. But if you want to make your networking layer really type-safe you'll want to create a dedicated `Call` type for each operation of your Web-API:

```swift
struct GetRandomImage: Call {
    typealias ResponseType = [String: Any]
    
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

You'll usually need to create your own dedicated client that either subclasses `AnyClient` or delegates the encoding of requests and decoding of responses to an `AnyClient` instance, as done here:

```swift
class GiphyClient: Client {
    private let anyClient = AnyClient(baseURL: URL(string: "https://api.giphy.com/v1/")!)
    
    var apiKey = "dc6zaTOxFJmzC"
    
    func encode<C: Call>(call: C) -> URLRequest {
        var request = anyClient.encode(call: call)
        
        // Append the API key to every request
        request.append(query: ["api_key": apiKey]) 
        
        return request
    }
    
    public func decode<C : Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.ResponseType.OutputType {
        do {
            // Use `AnyClient` to decode the response
            // If this fails, try to read error details from response body
            return try anyClient.decode(sessionTaskResult: result, for: call)
        } catch {
            // See if the backend sent detailed error information
            guard
                let response = result.httpResponse,
                let data = result.data,
                let errorDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let meta = errorDict?["meta"] as? [String: Any],
                let errorCode = meta["error_code"] as? String else {
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
struct RandomImage {
    var url: URL
    ...
}

struct GetRandomImage: Call {
    typealias ResponseType = RandomImage
    ...
}
```

In order for this to work, `RandomImage` must adopt the `ResponseDecodable` protocol:

```swift
extension RandomImage: ResponseDecodable {
    static func parse(data: Data, encoding: String.Encoding) throws -> RandomImage {
        let dict = try [String: Any].parse(data: data, encoding: encoding)
        
        guard let data = dict["data"] as? [String : Any], let url = data["image_url"] as? String else {
            throw throw DecodingError.invalidData(description: "invalid response. url not found")
        }
        
        return RandomImage(url: URL(string: url)!)
    }
}
```

This can of course be made a lot easier by using a JSON parsing library (like [Unbox](https://github.com/JohnSundell/Unbox)) and  a few lines of integration code:

```swift
protocol UnboxableParser: Unboxable, ResponseParser {}

extension UnboxableParser {
    static func parse(data: Data, encoding: String.Encoding) throws -> Self {
        return try unbox(data: data)
    }
}
```

Now we can write:

```swift
struct RandomImage: UnboxableParser {
    var url: URL
    
    init(unboxer: Unboxer) throws {
        url = try unboxer.unbox(keyPath: "data.image_url")
    }
}
```

### Type-Safety

With all the parts in place, users of your networking layer can now perform type-safe requests and get a type-safe response with a few lines of code:

```swift
let client = GiphyClient()
let call = GetRandomImage(tag: "cat")
let session = Session(with: client)

session.start(call: call) { result in
    result.onSuccess { value in
        print("image url: \(value.url)")
    }.onError { error in
        print("error: \(error)")
    }
}
```

### Convenience

There are multiple ways to make performing a call more convenient. You could write a dedicated `GiphyCall` that creates the correct `Client` and `Session` for your users:

```swift
protocol GiphyCall: Call {}

extension GiphyCall {
    func start(completion: @escaping (Result<ResponseType.OutputType>)->()) {
        let client = GiphyClient()
        let session = Session(with: client)
        
        session.start(call: self, completion: completion)
    }
}
```

When `GiphyCall` is adopted by `GetRandomImage` instead of `Call`, performing a request is much simpler:

```swift
GetRandomImage(tag: "cat").start { result in ... }
```

To make it easer to find supported calls, you could namespace your calls using an extension of your `Client`:

```swift
extension GiphyClient {
    struct GetRandomImage: GiphyCall { ... }
}
```

Xcode can now help developers find the right `Call` instance:

```swift
GiphyClient.GetRandomImage(tag: "cat").start { result in ... }
```

## Installation

**CocoaPods:**

```
pod "Endpoints"
```

**Carthage:**

```
github "tailoredmedia/Endpoints.git"
```

**Swift Package Manager:**

```
.Package(url: "https://github.com/tailoredmedia/Endpoints.git", majorVersion: 0)
```

## Example

To compile examples you need to fetch some git submodules using `git submodule update --init --recursive`.

## Requirements

- Swift 3
- iOS 8
- tvOS 9
- macOS 10.11
- watchOS 2.0
