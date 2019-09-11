import Foundation

/// A `ResponseParser` for types, that can be represented as a string
/// in a lossless fashion.
public struct StringConvertibleParser<Parsed: LosslessStringConvertible>: ResponseParser {

    public typealias OutputType = Parsed

    public static func parse(data: Data, encoding: String.Encoding) throws -> Parsed {
        guard let string = String(data: data, encoding: encoding) else {
            throw ParsingError.invalidData(description: "The data could not be converted to a string with the given encoding.")
        }

        guard let value = Parsed(string) else {
            throw ParsingError.invalidData(description: "The value '\(string)' could not be converted to \(Parsed.self)")
        }

        return value
    }
}
