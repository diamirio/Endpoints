import XCTest
@testable import Endpoints

class CodableStringTests: XCTestCase {
    func testIntString() throws {
        let model = try Model<Int>.parse(data: FileUtil.load(named: "ModelInt"), encoding: .utf8)
        XCTAssertEqual(42, model.value)
    }

    func testFloatString() throws {
        let model = try Model<Float>.parse(data: FileUtil.load(named: "ModelFloat"), encoding: .utf8)
        XCTAssertEqual(42.42, model.value)
    }

    func testDoubleString() throws {
        let model = try Model<Double>.parse(data: FileUtil.load(named: "ModelFloat"), encoding: .utf8)
        XCTAssertEqual(42.42, model.value)
    }

    func testBoolString() throws {
        var model = try Model<Bool>.parse(data: FileUtil.load(named: "ModelBoolTrue"), encoding: .utf8)
        XCTAssertTrue(model.value)

        model = try Model<Bool>.parse(data: FileUtil.load(named: "ModelBoolFalse"), encoding: .utf8)
        XCTAssertFalse(model.value)
    }

    fileprivate struct Model<T: LosslessStringConvertible>: JSONSelfDecodable {
        private let valueString: CodableString<T>
        var value: T {
            return valueString.value
        }

        private enum CodingKeys: String, CodingKey {
            case valueString = "value"
        }
    }
}
