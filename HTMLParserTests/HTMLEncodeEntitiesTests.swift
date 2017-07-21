//
//  HTMLEncodeEntitiesTests.swift
//  HTMLParserTests
//
//  Created by Raymond Mccrae on 21/07/2017.
//  Copyright © 2017 Raymond Mccrae. All rights reserved.
//

import XCTest
@testable import HTMLParser

class HTMLEncodeEntitiesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        if let value = "Dogs <<<<<<<<<< Cats".encodeHTMLEntities() {
            print(value)
        }
    }
    
}
