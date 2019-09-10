//
//  MultipartTests.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 04.09.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import XCTest
@testable import Endpoints

class MultipartTests: XCTestCase {

    private let multipartBody = MultipartBody(parts: [
        MultipartBody.Part(name: "testName",
                           data: "unittest1".data(using: .utf8)!,
                           filename: "testfile.txt",
                           mimeType: "text/plain",
                           charset: "utf-8"),
        MultipartBody.Part(name: "testName2",
                           data: "unittest2".data(using: .utf8)!,
                           mimeType: "text/plain")
        ])


    /// Create a request body that can be compared with the multipartBody property
    /// - Parameter boundary: The boundary without the two hyphens and CRLF
    private func createRequestDataString(boundary: String) -> String {
        // linefeeds here are only `\n` while multipart uses `\r\n`, therefore `\r` needs to be manually inserted
        let cr = "\r"
        return """
        --\(boundary)\(cr)
        Content-Disposition: form-data; name="testName"; filename="testfile.txt"\(cr)
        Content-Type: text/plain; charset=utf-8\(cr)
        \(cr)
        unittest1\(cr)
        --\(boundary)\(cr)
        Content-Disposition: form-data; name="testName2"\(cr)
        Content-Type: text/plain\(cr)
        \(cr)
        unittest2\(cr)
        --\(boundary)--
        """
    }

    func testContentTypeHeaderExists() {
        guard let contentTypeHeader = multipartBody.header?["Content-Type"] else {
            XCTFail("Content Type Header not present")
            return
        }

        XCTAssertEqual(contentTypeHeader, "multipart/form-data; boundary=\(multipartBody.boundary)")
    }

    func testBoundaryOccurences() {
        guard let requestDataString = String(data: multipartBody.requestData, encoding: .utf8) else {
            XCTFail("cannot read string value of requestData")
            return
        }

        print(requestDataString)

        let boundary = multipartBody.boundary
        let amountParts = multipartBody.parts.count

        let boundaryIndices = requestDataString.indicesOf(string: boundary)

        let partBoundaryString = "--\(boundary)\r\n"
        let partBoundaryIndices = requestDataString.indicesOf(string: partBoundaryString)

        let endBoundaryString = "--\(boundary)--"
        let endBoundaryIndices = requestDataString.indicesOf(string: endBoundaryString)

        XCTAssertEqual(amountParts + 1, boundaryIndices.count) // for every part & end
        XCTAssertEqual(amountParts, partBoundaryIndices.count)
        XCTAssertEqual(1, endBoundaryIndices.count)
        XCTAssertEqual(requestDataString.count - endBoundaryString.count, endBoundaryIndices.first)
    }

    func testMultipartRequestData() {
        XCTAssertEqual(
            createRequestDataString(boundary: multipartBody.boundary),
            String(data: multipartBody.requestData, encoding: .utf8)
        )
    }

    func testMultipartHTTPBinCall() {
        struct PostCall: Call {
            typealias ResponseType = HTTPBinResponse

            var request: URLRequestEncodable {
                return Request(.post, "post", body: multipartBody)
            }

            let multipartBody: MultipartBody
        }

        let client = AnyClient(baseURL: URL(string: "https://httpbin.org")!)
        let session = Session(with: client)
        let call = PostCall(multipartBody: multipartBody)

        let exp = expectation(description: "call finishes")

        session.start(call: call) { (result) in
            result.onError { (error) in
                XCTFail(":(")
            }.onSuccess { [weak self] (value) in
                guard let self = self else { return }

                XCTAssertEqual("unittest1", value.files["testName"])
                XCTAssertEqual("unittest2", value.form["testName2"])
                XCTAssertEqual("multipart/form-data; boundary=\(self.multipartBody.boundary)", value.headers["Content-Type"])
            }

            exp.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }
}

private extension String {
    func indicesOf(string: String) -> [Int] {
        var indices: [Int] = []
        var searchStartIndex = startIndex

        while searchStartIndex < endIndex,
            let range = range(of: string, range: searchStartIndex..<endIndex), !range.isEmpty {
                let index = distance(from: startIndex, to: range.lowerBound)
                indices.append(index)
                searchStartIndex = range.upperBound
        }

        return indices
    }
}
