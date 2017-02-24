# Endpoints

Endpoints makes it easy to write a type-safe network abstraction layer for any Web-API.

It requires Swift 3, makes heavy use of generics (and generalised existentials) and protocols (and protocol extensions). It also encourages a clean separation of concerns and the use of value types (i.e. structs).

## Usage

### Basics

Here's how to load a random image from Giphy.

```swift
// A client is responsible for encoding and parsing all calls for a given Web-API.
let client = AnyClient(baseURL: URL(string: "https://api.giphy.com/v1/")!)

// A call encapsulates the request that is sent to the server and the type that is expected in the response.
let call = AnyCall<Data>(Request(.get, "gifs/random", query: [ "tag": "cat", "api_key": "dc6zaTOxFJmzC" ]))

// A session wraps `URLSession` and allows you to start the request for the call and get the parsed response object (or an error) in a completion block.
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

### Response Parsing

A call is supposed to know exactly what response to expect from its request. It delegates the parsing of the response to a `ResponseParser`.

Some built-in types already adopt the `ResponseParser` protocol (using protocol extensions), so you can for example turn any response into a JSON array or dictionary:

```swift
// Replace `Data` with any `ResponseParser` implementation
let call = AnyCall<[String: Any]>(Request(.get, "gifs/random", query: [ "tag": "cat", "api_key": "dc6zaTOxFJmzC" ]))
...
session.start(call: call) { result in
    result.onSuccess { value in
        //value is now a JSON dictionary 🎉
    }
}
```

### Type-Safe Calls

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

You'll usually need to create your own dedicated client that either subclasses `AnyClient` or delegates the encoding of requests and parsing of responses to an `AnyClient` instance, as done here:

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
    
    public func parse<C : Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.ResponseType.OutputType {
        do {
            // use `AnyClient` to parse the response
            // if this fails, try to read error details from response body
            return try anyClient.parse(sessionTaskResult: result, for: call)
        } catch {
            // see if the backend sent detailed error information
            guard
                let response = result.httpResponse,
                let data = result.data,
                let errorDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let meta = errorDict?["meta"] as? [String: Any],
                let errorCode = meta["error_code"] as? String else {
                // no error info from backend -> rethrow default error
                throw error
            }
            
            //propagate error that contains errorCode as reason from backend
            throw StatusCodeError.unacceptable(code: response.statusCode, reason: errorCode)
        }
    }
}
```

### Custom Response Types

TBD

### Convenience

TBD

## Installation

**CocoaPods:**

```
pod "Endpoints", "~> 0.3"
```

**Carthage:**

```
github "tailoredmedia/Endpoints.git" ~> 0.3
```

**Swift Package Manager:**

```
.Package(url: "https://github.com/tailoredmedia/Endpoints.git", majorVersion: 0, minor: 3),
```

## Example

To compile examples you need to download some dependencies using the Swift Package Manager.
Just open Terminal at `Endpoints/Example/Core` and type `swift package fetch`.

## Requirements

- Swift 3
- iOS 8
- tvOS 9
- macOS 10.11
- watchOS 2.0
