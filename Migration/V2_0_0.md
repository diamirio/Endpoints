# v2.0.0 - Changelog & Migration Guide

## Calls

### AnyCall

* `AnyCall.ResponseType` was renamed to `AnyCall.Parser`. This does also affect all subtypes.

#### Migrate
- use `AnyCall.Parser` instead of `AnyCall.ResponseType`

### Call

* `Call.ResponseType` was renamed to `Call.Parser`. This does also affect all subtypes.

#### Migrate
- use `YourCall.Parser` instead of `YourCall.ResponseType`

## Convenience

### NoContentParser

Previously, when you did not need anything after a successful response, `typealias ResponseType = Data` was used.  

Now, you can use `typealias Parser = NoContentParser` to better indicate that the response does not matter.
Note, that the `OutputType` is changed to `Void` then!

### StringParser / DictionaryParser / DataResponseParser

Previously, `String`, `Dictionary`, `Data` did conform to `ResponseParser`.  
This is no longer the case. Instead, there are dedicated `ResponseParser` types.

#### Migrate
Swap types for the `Parser` typealias:
* `Data` -> `DataResponseParser`
* `Dictionary` -> `DictionaryParser`
* `String` -> `StringParser`

### DataParser

* `static parse` func changed to instance func. 
* Require empty initializer.
* `DataParser` no longer defines itself as a default `OutputType`

#### Migrate
- remove static keyword for `parse(data:encoding:)` func
- add `init() { /* your init code */ }` to any `DataParser` subtype
- use `YourParser().parse(data:encoding:)` instead of `YourParser.parse(data:encoding:)`

### DecodableParser

* everything for parsing now done via instance instead of statically

#### Migrate
- remove static keyword for `parse(data:)` func
- use `YourParser().parse(data:)` instead of `YourParser.parse(data:)`

### JSONDecodableParser & JSONSelfDecodable

* **removed**

#### Migrate
- stop letting your `OutputType`s conform to any `DataParser` subtype
- let your `OutputType` conform to `Decodable`
- use an `typealias Parser = JSONParser<Type>`

Example

```swift
// previously
struct City: JSONSelfDecodable {
    // ...
}

struct CityCall: Call {
    typealias ResponseType = City

    // ....
}

// now
struct City: Decodable {
    // ...
}

struct CityCall: Call {
    typealias Parser = JSONParser<City>

    // ...
}
```

### JSONDecoding + Array

* **removed**

#### Migrate
- use `JSONParser<[Element]>` as the `Parser` of a call instead of `[Element]` directly.

### ResponseParser

* everything for parsing now done via instance instead of statically

#### Migrate
- remove static keyword for `parse(response:data:)` func
- use `YourParser().parse(response:data:)` instead of `YourParser.parse(response:data:)`

### StringConvertibleParser

* everything for parsing now done via instance instead of statically

#### Migrate
- use `StringConvertibleParser<YourType>().parse` instead of `StringConvertibleParser<YourType>.parse`
