import Foundation

extension Array: ResponseParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Array {
        guard let array = try parseJSON(data: data) as? Array else {
            throw ParsingError.invalidData(description: "JSON structure is not an Array")
        }

        return array
    }
}

extension Array where Element: Response & Decodable {

    public static func parseJSON(data: Data) throws -> Any {
        return try Element.decoder.decode(OutputType.self, from: data)
    }
}
