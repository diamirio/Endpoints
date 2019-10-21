import XCTest
@testable import Endpoints

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

    func testDecodingEncoding() throws {
        let model = CodableString(42.42)

        let codedModel = try JSONParser<CodableString<Double>>().parse(
            data: try model.toJSON(),
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
            return valueString.value
        }

        private enum CodingKeys: String, CodingKey {
            case valueString = "value"
        }
    }
}
