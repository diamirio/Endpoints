# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Endpoints** Swift package - a type-safe network abstraction layer for Web APIs. It provides a clean separation of concerns using protocols and generics, with heavy use of Swift's type system to ensure compile-time safety for network operations.

### Core Architecture

The library is built around three main concepts:
- **Call**: Represents a specific API endpoint request and expected response type
- **Client**: Handles encoding requests and parsing responses for a Web API  
- **Session**: Manages URLSession and executes calls asynchronously

Key architectural patterns:
- Protocol-oriented design with extensive use of generics
- Value types (structs) preferred over reference types
- Async/await throughout (no completion handlers)
- Response parsing delegation via `ResponseParser` protocol

### Directory Structure

- `Sources/Core/`: Core protocols (`Call`, `Client`, `Session`, `Request`)
- `Sources/Parsing/`: Response parsers (`JSONParser`, `DataResponseParser`, etc.)
- `Sources/Body/`: Request body types (JSON, form-encoded, multipart)
- `Sources/Async/`: Async implementations (`AnyClient`, `Session`)
- `Sources/Convenience/`: Helper types and extensions
- `Sources/Error/`: Error types specific to Endpoints
- `Sources/Testing/`: Testing utilities (`FakeSession`, `FakeResultProvider`)
- `EndpointsTestbed/`: Example iOS app demonstrating usage patterns

## Development Commands

### Building and Testing
```bash
# Build the package
swift build

# Run all tests  
swift test

# Build with verbose output
swift build -v

# Run tests with verbose output
swift test -v
```

### Code Formatting
```bash
# Format code (using SwiftFormat dependency)
swift run swiftformat .

# Check formatting without changes
swift run swiftformat . --lint
```

### Example App (EndpointsTestbed)
The testbed iOS app can be built and run through Xcode by opening `EndpointsTestbed/EndpointsTestbed.xcodeproj`.

## Key Implementation Patterns

### Creating Type-Safe Calls
```swift
struct GetUser: Call {
    typealias Parser = JSONParser<User>
    
    let userId: String
    
    var request: URLRequestEncodable {
        Request(.get, "users/\(userId)")
    }
}
```

### Custom Clients
Subclass `AnyClient` or implement `Client` protocol. Override `encode(call:)` for request manipulation or `parse(response:data:for:)` for response handling.

### Response Parsers
- `JSONParser<T>` for Codable types
- `DataResponseParser` for raw Data
- `DictionaryParser<K,V>` for JSON dictionaries  
- `StringParser` for string responses
- `NoContentParser` when response content doesn't matter

## Swift Version and Compatibility

- Requires Swift 6.2+ (see Package.swift)
- Supports iOS 13+, macOS 10.15+, tvOS 12+, watchOS 6+, visionOS 1+
- Built for modern Swift concurrency (async/await)

## Migration Notes

Major version changes (v2.0.0, v3.0.0) included breaking changes. See `Migration/` directory for detailed upgrade guides. Most notably:
- v3.0.0 moved to native async/await (removed completion handler APIs)
- Response parsing moved from static to instance methods
- `Session.start()` replaced with `Session.dataTask(for:)`