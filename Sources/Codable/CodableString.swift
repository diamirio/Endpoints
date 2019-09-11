/// Generic wrapper for LosslessStringConvertible Codable support
///
/// e.g. "12" can be converted to Int, which would otherwise not be possible automatically
public struct CodableString<Value: LosslessStringConvertible>: Codable {

    public var value: Value

    /// Init with an initial value
    /// - Parameter value: the inital Value
    public init(_ value: Value) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let valueString = try container.decode(String.self)

        guard let value = Value(valueString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "The string \(valueString) is not representable as a \(Value.self)"
            )
        }

        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.description)
    }
}
