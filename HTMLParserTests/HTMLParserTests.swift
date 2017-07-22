//
//  HTMLParserTests.swift
//  HTMLParserTests
//
//  Created by Raymond Mccrae on 20/07/2017.
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
@testable import HTMLParser

class HTMLParserTests: XCTestCase {

    func test_parse_data_empty() {
        let data = Data()
        var threwError = false
        do {
            let parser = HTMLParser()
            try parser.parse(data: data, handler: { (event) in
                XCTFail()
            })
            XCTFail()
        }
        catch HTMLParser.Error.emptyDocument {
            threwError = true
        }
        catch {
            XCTFail()
        }

        XCTAssertTrue(threwError)
    }

    func test_parse_strint_empty() {
        let string = ""
        var threwError = false
        do {
            let parser = HTMLParser()
            try parser.parse(string: string, handler: { (event) in
                XCTFail()
            })
            XCTFail()
        }
        catch HTMLParser.Error.emptyDocument {
            threwError = true
        }
        catch {
            XCTFail()
        }

        XCTAssertTrue(threwError)
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        var calledStartElement = false
        var calledCharacters = false
        let parser = HTMLParser()
        do {
            try parser.parse(string: "<hello>こんにちは</hello>") { (event) in
                switch event {
                case let .startElement(name, _, _):
                    XCTAssertEqual(name, "hello")
                    calledStartElement = true
                case let .characters(text, _):
                    XCTAssertEqual(text, "こんにちは")
                    calledCharacters = true
                default:
                    break
                }
            }
        }
        catch {
            XCTFail()
        }
        
        XCTAssertTrue(calledStartElement)
        XCTAssertTrue(calledCharacters)
    }
    
}
