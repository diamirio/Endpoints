// Copyright © 2023 DIAMIR. All Rights Reserved.

@testable import Endpoints
import XCTest

class CodableStringTests: XCTestCase {
    func testIntString() throws {
        let model = try JSONParser<Model<Int>>().parse(data: FileUtil.load(named: "ModelInt"), encoding: .utf8)
        XCTAssertEqual(42, model.value)
    }

    func testFloatString() throws {
        let model = try JSONParser<Model<Float>>().parse(data: FileUtil.load(named: "ModelFloat"), encoding: .utf8)
        XCTAssertEqual(42.42, model.value)
    }

    func testDoubleString() throws {
        let model = try JSONParser<Model<Double>>().parse(data: FileUtil.load(named: "ModelFloat"), encoding: .utf8)
        XCTAssertEqual(42.42, model.value)
    }

    func testBoolString() throws {
        var model = try JSONParser<Model<Bool>>().parse(data: FileUtil.load(named: "ModelBoolTrue"), encoding: .utf8)
        XCTAssertTrue(model.value)

        model = try JSONParser<Model<Bool>>().parse(data: FileUtil.load(named: "ModelBoolFalse"), encoding: .utf8)
        XCTAssertFalse(model.value)
    }

    // do not test Model<?> directly, as macOS 10.14 or earlier, and iOS 12 and earlier
    // do not support de-/encoding top level literals
    // https://bugs.swift.org/browse/SR-6163
    // https://bugs.swift.org/browse/SR-7213
    func testDecodingEncoding() throws {
        let model: Model<Double> = try JSONParser().parse(data: FileUtil.load(named: "ModelFloat"), encoding: .utf8)
        let data = try model.toJSON()

        let codedModel: Model<Double> = try JSONParser().parse(
            data: data,
            encoding: .utf8
        )

        XCTAssertEqual(
            model.value,
            codedModel.value
        )
    }

    fileprivate struct Model<T: LosslessStringConvertible>: Codable {
        private let valueString: CodableString<T>
        var value: T {
            valueString.value
        }

        private enum CodingKeys: String, CodingKey {
            case valueString = "value"
        }
    }
}
