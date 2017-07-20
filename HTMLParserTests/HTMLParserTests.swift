//
//  HTMLParserTests.swift
//  HTMLParserTests
//
//  Created by Raymond Mccrae on 20/07/2017.
//  Copyright © 2017 Raymond Mccrae. All rights reserved.
//

import XCTest
@testable import HTMLParser

class HTMLParserTests: XCTestCase {
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        var calledStartElement = false
        let parser = HTMLParser()
        do {
            try parser.parse(string: "<hello>") { (event) in
                switch event {
                case let .startElement(name, attributes, _):
                    XCTAssertEqual(name, "hello")
                    calledStartElement = true
                default:
                    break
                }
            }
        }
        catch {
            XCTFail()
        }
        
        XCTAssertTrue(calledStartElement)
    }
    
}
