import Foundation

/// A `ResponseParser` for types, that can be represented as a string
/// in a lossless fashion.
///
/// The `StringConvertibleParser` also supports converting strings.
/// First it tries to directly convert the string, if that fails,
/// then newlines, spaces and quotes are trimmed and the conversion is tried again.
public struct StringConvertibleParser<Parsed: LosslessStringConvertible>: ResponseParser {

    public typealias OutputType = Parsed

    public init() {}

    public func parse(data: Data, encoding: String.Encoding) throws -> Parsed {
        guard var string = String(data: data, encoding: encoding) else {
            throw ParsingError.invalidData(description: "The data could not be converted to a string with the given encoding.")
        }

        guard let value = Parsed(string) else {

            string = string.trimmingCharacters(in:
                CharacterSet.whitespacesAndNewlines
                    .union(CharacterSet(charactersIn: "\""))
            )

            guard let value = Parsed(string) else {
                throw ParsingError.invalidData(description: "The value '\(string)' could not be converted to \(Parsed.self)")
            }

            return value
        }

        return value
    }
}

// MARK: - Typealiases for most commonly used LosslessStringConvertibles

public typealias BoolParser   = StringConvertibleParser<Bool>
public typealias DoubleParser = StringConvertibleParser<Double>
public typealias FloatParser  = StringConvertibleParser<Float>
public typealias IntParser    = StringConvertibleParser<Int>
