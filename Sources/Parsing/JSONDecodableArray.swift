import Foundation

/**
 Array parsing directly as a response type of `Call`s is only supported via `Decodable`.
 If you want to support another parsing mechanism, then you need to implement
 an own `ResponseParser` and use that.

 Example:
 ```
 public struct CustomArrayParser<Element>: ResponseParser {

     public typealias OutputType = [Element]

     public static func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
         // ...
     }
 }

 public struct CustomCall: Call {
     public typealias ResponseType = CustomArrayParser<String>

     public var request: URLRequestEncodable {
         // ...
     }
 }
 ```
 */
extension Array: JSONDecodableParser, DecodableParser, ResponseParser, DataParser where Element: Decodable {
    public static func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return try jsonDecoder.decode(OutputType.self, from: data)
    }
}
