//
//  HTMLSAXParserTests.swift
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
@testable import HTMLSAXParser

class HTMLParserTests: XCTestCase {

    fileprivate static let bundle: Bundle = Bundle.init(for: HTMLParserTests.self)
    fileprivate static let testHTMLDocumentUTF8: Data = loadHTMLDocumentData(named: "test_uft16le")
    fileprivate static let testHTMLArticleWithImages: Data = loadHTMLDocumentData(named: "article_with_images")

    static func loadHTMLDocumentData(named: String) -> Data {
        let docuemntURL = bundle.url(forResource: named, withExtension: "html")!
        guard let documentData = try? Data(contentsOf: docuemntURL) else {
            fatalError("Test data file \(named).html not found within test bundle")
        }
        return documentData
    }

    func test_parse_data_empty() {
        let data = Data()
        var threwError = false
        do {
            let parser = HTMLSAXParser()
            try parser.parse(data: data, handler: { (_, _) in
                XCTFail("Empty document should not generate any events")
            })
            XCTFail("Empty document should throw an error")
        } catch HTMLSAXParser.Error.emptyDocument {
            threwError = true
        } catch {
            XCTFail("Wrong type of error thrown")
        }

        XCTAssertTrue(threwError)
    }

    func test_parse_string_empty() {
        let string = ""
        var threwError = false
        do {
            let parser = HTMLSAXParser()
            try parser.parse(string: string, handler: { (_, _) in
                XCTFail("Empty document should not generate any events")
            })
            XCTFail("Empty document should throw an error")
        } catch HTMLSAXParser.Error.emptyDocument {
            threwError = true
        } catch {
            XCTFail("Wrong type of error thrown")
        }

        XCTAssertTrue(threwError)
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        var calledStartElement = false
        var calledCharacters = false
        let parser = HTMLSAXParser()
        do {
            try parser.parse(string: "<hello>こんにちは</hello>") { (_, event) in
                switch event {
                case let .startElement(name, _):
                    XCTAssertEqual(name, "hello")
                    calledStartElement = true
                case let .characters(text):
                    XCTAssertEqual(text, "こんにちは")
                    calledCharacters = true
                default:
                    break
                }
            }
        } catch {
            XCTFail("Unexpected error thrown")
        }

        XCTAssertTrue(calledStartElement)
        XCTAssertTrue(calledCharacters)
    }

    func testInvalidHTML() {
        let parser = HTMLSAXParser()
        do {
            try parser.parse(string: "<hello<") { (_, event) in
                switch event {
                case let .error(message):
                    print("Error: \(message)")
                default:
                    break
                }
            }
        } catch {

        }
    }

    func testHTMLAttributes() {
        let parser = HTMLSAXParser()
        var startElementCount = 0, endElementCount = 0, startDocCount = 0, endDocCount = 0

        do {
            let html = "<p id=\"123\" class=\"paragraph\" style=\"background-color: red\" hidden>"
            try parser.parse(string: html) { (_, event) in
                switch event {
                case let .startElement(name, attributes):
                    startElementCount += 1
                    XCTAssertEqual(name, "p")
                    XCTAssertEqual(attributes["id"], "123")
                    XCTAssertEqual(attributes["class"], "paragraph")
                    XCTAssertEqual(attributes["style"], "background-color: red")
                    XCTAssertEqual(attributes["hidden"], "")
                    XCTAssertEqual(attributes.count, 4)

                case let .endElement(name):
                    endElementCount += 1
                    XCTAssertEqual(name, "p")

                case .startDocument:
                    startDocCount += 1

                case .endDocument:
                    endDocCount += 1

                default:
                    XCTFail("Unexpected event")
                }
            }
        } catch {
            XCTFail("Unexpected error thrown")
        }

        XCTAssertEqual(startDocCount, 1)
        XCTAssertEqual(endDocCount, 1)
        XCTAssertEqual(startElementCount, 1)
        XCTAssertEqual(endElementCount, 1)
    }

    func imageSources(from htmlData: Data) throws -> [String] {
        var sources: [String] = []
        let parser = HTMLSAXParser()
        try parser.parse(data: htmlData) { _, event in
            switch event {
            case let .startElement(name, attributes) where name == "img":
            if let source = attributes["src"] {
                sources.append(source)
                }
            default:
                break
            }
        }
        return sources
    }

    func testImageExtraction() {
        do {
            let imageSources = try self.imageSources(from: HTMLParserTests.testHTMLArticleWithImages)
            // swiftlint:disable line_length
            XCTAssertEqual(imageSources, [
                "https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/01-COBRA-SUCURI-3M-WAGNER-MEIER_MG_2458.JPG/640px-01-COBRA-SUCURI-3M-WAGNER-MEIER_MG_2458.JPG",
                "https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/Brachypelma_smithi_2009_G03.jpg/640px-Brachypelma_smithi_2009_G03.jpg",
                "https://upload.wikimedia.org/wikipedia/commons/d/d7/Panamanian_night_monkey.jpg"])
            // swiftlint:enable line_length
        } catch {
            XCTFail("Error thrown while parsing")
        }
    }

}
