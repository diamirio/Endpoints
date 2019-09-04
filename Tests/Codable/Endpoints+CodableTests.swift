//
//  Endpoints+CodableTests.swift
//  Endpoints-iOS
//
//  Created by Robin Mayerhofer on 04.09.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import XCTest
@testable import Endpoints

class EndpointsCodableTests: XCTestCase {

    override class func setUp() {
        //
    }

    override func tearDown() {
        //
    }

    func testDecodingArray() throws {
        let decoded = try [City].parse(data: FileUtil.load(named: "CityArray", withExtension: "json"), encoding: .utf8)

        XCTAssertEqual(decoded.count, 7, "there should be exactly 7 elements in the array")
        XCTAssertEqual(decoded.first, City(name: "Biehle", postalCode: 9753), "the first element should have the right name / postalCode")
    }

    func testEncoding() throws {
        let city = City(name: "test1234", postalCode: 1234)
        let jsonData: Data = try city.toJSON()

        let decoded = try City.decoder.decode(City.self, from: jsonData)

        XCTAssertEqual(city, decoded, "Encoding -> Decoding should result in the same values")
    }

    private struct City: Codable, DecodableParser, Equatable {
        let name: String
        let postalCode: Int
    }
}
