import Foundation
import ObjectMapper
import Endpoints

extension JSONEncodedBody {
    init<M: BaseMappable>(mappable: M) throws {
        let json = Mapper<M>().toJSON(mappable)
        try self.init(jsonObject: json)
    }
}

public protocol MappableParser: Mappable, ResponseParser {}

public extension MappableParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Self {
        let dict = try [String: Any].parse(data: data, encoding: encoding)
        
        guard let object:Self = Mapper().map(JSON: dict) else {
            throw ParsingError.invalidData(description: "JSON structure could not be mapped to \(self) class")
        }
        
        return object
    }
}

public class MappableArray<Element: Mappable>: ResponseParser {
    public typealias OutputType = [Element]
    
    //not to be initialized
    private init() {}
    
    public static func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        let jsonArray = try [[String: Any]].parse(data: data, encoding: encoding)
        
        guard let array:OutputType = Mapper().mapArray(JSONArray: jsonArray) else {
            throw ParsingError.invalidData(description: "JSON structure could not be mapped to \(OutputType.self) class")
        }
        
        return array
    }
}
