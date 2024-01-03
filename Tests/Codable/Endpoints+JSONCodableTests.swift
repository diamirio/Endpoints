// Copyright © 2023 DIAMIR. All Rights Reserved.

@testable import Endpoints
import XCTest

class EndpointsJSONCodableTests: XCTestCase {
    func testDecodingArray() throws {
        let decoded = try JSONParser<[City]>().parse(data: FileUtil.load(named: "CityArray"), encoding: .utf8)

        validateCityArray(decoded)
    }

    // this test case is relevant, as there is a difference between using [City].parse
    // and parse on the same type, but with the heavy generics use of Endpoints
    func testDecodingArrayViaResponse() async throws {
        let client = AnyClient(baseURL: URL(string: "www.tailored-apps.com")!)
        let call = CitiesCall()

        let cities = try await client.parse(
            response: FakeHTTPURLResponse(status: 200, header: nil),
            data: FileUtil.load(named: "CityArray"),
            for: call
        )

        validateCityArray(cities)
    }

    func testEncoding() throws {
        let city = City(name: "test1234", postalCode: 1234)
        let jsonData: Data = try city.toJSON()

        let decoded = try City.jsonDecoder.decode(City.self, from: jsonData)

        XCTAssertEqual(city, decoded, "Encoding -> Decoding should result in the same values")
    }

    func testUsingCustomDecoder() throws {
        do {
            _ = try DateCrashParser<Person>().parse(data: FileUtil.load(named: "Person"), encoding: .utf8)
            XCTFail("parsing should not succeed")
        } catch ExpectedError.decoderWasReplaced {
            // expected
        }
    }

    func testUsingCustomDecoderAndAnyClient() async throws {
        let client = AnyClient(baseURL: URL(string: "www.tailored-apps.com")!)
        let call = PersonCall()

        do {
            _ = try await client.parse(
                response: FakeHTTPURLResponse(status: 200, header: nil),
                data: FileUtil.load(named: "Person"),
                for: call
            )
            XCTFail("parsing should not succeed")
        } catch ExpectedError.decoderWasReplaced {
            // expected
        }
    }

    private func validateCityArray(_ cities: [City]) {
        XCTAssertEqual(cities.count, 7, "there should be exactly 7 elements in the array")
        XCTAssertEqual(cities.first, City(name: "Biehle", postalCode: 9753), "the first element should have the right name / postalCode")
    }

    fileprivate static func getDateCrashDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { _ -> Date in
            throw ExpectedError.decoderWasReplaced
        }

        return decoder
    }

    private struct CitiesCall: Call {
        typealias Parser = JSONParser<[City]>

        var request: URLRequestEncodable {
            Request(.get)
        }
    }

    private struct PersonsCall: Call {
        typealias Parser = DateCrashParser<[Person]>

        var request: URLRequestEncodable {
            Request(.get)
        }
    }

    private struct PersonCall: Call {
        typealias Parser = DateCrashParser<Person>

        var request: URLRequestEncodable {
            Request(.get)
        }
    }

    private struct City: Codable, Equatable {
        static var jsonDecoder: JSONDecoder {
            JSONDecoder()
        }

        let name: String
        let postalCode: Int
    }

    fileprivate struct Person: Decodable {
        let name: String
        let birthday: Date
    }

    private enum ExpectedError: LocalizedError {
        case decoderWasReplaced
    }
}

extension EndpointsJSONCodableTests.Person {
    static var jsonDecoder: JSONDecoder {
        EndpointsJSONCodableTests.getDateCrashDecoder()
    }
}

class DateCrashParser<T: Decodable>: JSONParser<T> {
    override var jsonDecoder: JSONDecoder {
        EndpointsJSONCodableTests.getDateCrashDecoder()
    }
}
