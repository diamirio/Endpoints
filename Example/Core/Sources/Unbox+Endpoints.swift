import Foundation
import Unbox
import Endpoints

public protocol UnboxableParser: Unboxable, CallResponseParser {}

public extension UnboxableParser {
    static func parse(data: Data, encoding: String.Encoding) throws -> Self {
        return try unbox(data: data)
    }
}

public class UnboxableArray<Element: Unboxable>: CallResponseParser {
    public typealias OutputType = [Element]
    
    public static func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return try unbox(data: data)
    }
}
