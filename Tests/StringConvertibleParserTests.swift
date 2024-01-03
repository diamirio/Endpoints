// Copyright © 2023 DIAMIR. All Rights Reserved.

import XCTest
@testable import Endpoints

class StringConvertibleParserTests: XCTestCase {

    func testIntString() throws {
        let n1 = try IntParser().parse(data: FileUtil.load(named: "StringInt"), encoding: .utf8)
        let n2 = try IntParser().parse(data: FileUtil.load(named: "StringQuotesInt"), encoding: .utf8)
        XCTAssertEqual(42, n1)
        XCTAssertEqual(42, n2)
    }

    func testFloatString() throws {
        let n1 = try FloatParser().parse(data: FileUtil.load(named: "StringFloat"), encoding: .utf8)
        let n2 = try FloatParser().parse(data: FileUtil.load(named: "StringQuotesFloat"), encoding: .utf8)
        XCTAssertEqual(42.42, n1)
        XCTAssertEqual(42.42, n2)
    }

    func testDoubleString() throws {
        let n1 = try DoubleParser().parse(data: FileUtil.load(named: "StringFloat"), encoding: .utf8)
        let n2 = try DoubleParser().parse(data: FileUtil.load(named: "StringQuotesFloat"), encoding: .utf8)
        XCTAssertEqual(42.42, n1)
        XCTAssertEqual(42.42, n2)
    }

    func testBoolString() throws {
        var b1 = try BoolParser().parse(data: FileUtil.load(named: "StringBoolTrue"), encoding: .utf8)
        var b2 = try BoolParser().parse(data: FileUtil.load(named: "StringQuotesBoolTrue"), encoding: .utf8)
        XCTAssertTrue(b1)
        XCTAssertTrue(b1)

        b1 = try BoolParser().parse(data: FileUtil.load(named: "StringBoolFalse"), encoding: .utf8)
        b2 = try BoolParser().parse(data: FileUtil.load(named: "StringQuotesBoolFalse"), encoding: .utf8)
        XCTAssertFalse(b1)
        XCTAssertFalse(b2)
    }

    fileprivate struct Model<T: LosslessStringConvertible> {
        let value: T
    }
}
