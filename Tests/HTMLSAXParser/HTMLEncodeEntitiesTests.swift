//
//  HTMLEncodeEntitiesTests.swift
//  HTMLParserTests
//
//  Created by Raymond Mccrae on 21/07/2017.
//  Copyright © 2017 Raymond McCrae.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
@testable import HTMLSAXParser

class HTMLEncodeEntitiesTests: XCTestCase {

    func testStringEncodeHTMLEntities() {
        XCTAssertEqual("".encodeHTMLEntities(), "")
        XCTAssertEqual("A".encodeHTMLEntities(), "A")
        XCTAssertEqual("&".encodeHTMLEntities(), "&amp;")
        XCTAssertEqual("<".encodeHTMLEntities(), "&lt;")
        XCTAssertEqual(">".encodeHTMLEntities(), "&gt;")
        XCTAssertEqual("€".encodeHTMLEntities(), "&euro;")

        XCTAssertEqual("\"".encodeHTMLEntities(), "&quot;")
        XCTAssertEqual("\"".encodeHTMLEntities(quoteCharacter: .none), "\"")
        XCTAssertEqual("\"".encodeHTMLEntities(quoteCharacter: .singleQuote), "\"")
        XCTAssertEqual("\"".encodeHTMLEntities(quoteCharacter: .doubleQuote), "&quot;")

        XCTAssertEqual("'".encodeHTMLEntities(), "'")
        XCTAssertEqual("'".encodeHTMLEntities(quoteCharacter: .none), "'")
        XCTAssertEqual("'".encodeHTMLEntities(quoteCharacter: .singleQuote), "&apos;")
        XCTAssertEqual("'".encodeHTMLEntities(quoteCharacter: .doubleQuote), "'")
    }

    func testEmptyDataEncodeHTMLEntities() {
        let emptyData = Data()
        guard let result = emptyData.encodeHTMLEntities() else {
            XCTFail("encodeHTMLEntities should not return nil")
            return
        }
        XCTAssert(result.isEmpty, "Resulting Data object should have zero length")
    }

    func testInvalidCharDataEncodeHTMLEntities() {
        let invalidData = Data([0xff])
        let result = invalidData.encodeHTMLEntities()
        XCTAssertEqual(result, nil)
    }

}
