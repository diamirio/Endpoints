import Foundation

public enum ParsingError: LocalizedError {
    case missingData
    case invalidData(description: String)
 
    public var errorDescription: String? {
        switch self {
        case .missingData:
            return "no data"
        case .invalidData(let desc):
            return desc
        }
    }
}

public protocol DataParser {
    associatedtype OutputType = Self
    
    static func parse(data: Data, encoding: String.Encoding) throws -> OutputType
}

extension DataParser {
    public static func parseJSON(data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
}

extension Data: DataParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Data {
        return data
    }
}

extension String: DataParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> String {
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw ParsingError.invalidData(description: "String could not be parsed with encoding \(encoding.rawValue)")
        }
    }
}

extension Dictionary: DataParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Dictionary {
        guard let dict = try parseJSON(data: data) as? Dictionary else {
            throw ParsingError.invalidData(description: "JSON structure is not an Object")
        }
        
        return dict
    }
}

extension Array: DataParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Array {
        guard let array = try parseJSON(data: data) as? Array else {
            throw ParsingError.invalidData(description: "JSON structure is not an Array")
        }
        
        return array
    }
}
