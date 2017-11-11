//
//  HTMLSAXParser.swift
//  HTMLSAXParser
//
//  Created by Raymond McCrae on 20/07/2017.
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

import Foundation
import CHTMLSAXParser

public protocol HTMLSAXParseContext {

    /// The current parsing location during the parsing process.
    var location: HTMLSAXParser.Location { get }
    var systemId: String? { get }
    var publicId: String? { get }

    /**
     Aborts the current HTML parsings to prevent further calls
     to the parser event handler.
     */
    func abortParsing()

}

open class HTMLSAXParser {

    public struct ParseOptions: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let recover = ParseOptions(rawValue: Int(HTML_PARSE_RECOVER.rawValue))
        public static let noDefaultDTD = ParseOptions(rawValue: Int(HTML_PARSE_NODEFDTD.rawValue))
        public static let noError = ParseOptions(rawValue: Int(HTML_PARSE_NOERROR.rawValue))
        public static let noWarning = ParseOptions(rawValue: Int(HTML_PARSE_NOWARNING.rawValue))
        public static let pedantic = ParseOptions(rawValue: Int(HTML_PARSE_PEDANTIC.rawValue))
        public static let noBlanks = ParseOptions(rawValue: Int(HTML_PARSE_NOBLANKS.rawValue))
        public static let noNetwork = ParseOptions(rawValue: Int(HTML_PARSE_NONET.rawValue))
        public static let noImpliedElements = ParseOptions(rawValue: Int(HTML_PARSE_NOIMPLIED.rawValue))
        public static let compactTextNodes = ParseOptions(rawValue: Int(HTML_PARSE_COMPACT.rawValue))
        public static let ignoreEncodingHint = ParseOptions(rawValue: Int(HTML_PARSE_IGNORE_ENC.rawValue))

        /// Default set of parse options.
        public static let `default`: ParseOptions = [
            .recover,
            .noBlanks,
            .noNetwork,
            .noImpliedElements,
            .compactTextNodes]
    }

    public struct Location {
        public let line: Int
        public let column: Int
    }

    public enum Event {
        /// Event parser found the start of the document.
        case startDocument

        /// Event parser found the end of the document.
        case endDocument

        /// Event parser found an opening html tag.
        case startElement(name: String, attributes: [String: String])

        /// Event parser found an ending html tag.
        case endElement(name: String)

        /// Event parser found character nodes.
        case characters(text: String)

        /// Event parser found a comment node.
        case comment(text: String)

        /// Event parser found a CDATA block.
        case cdata(block: Data)

        /// Event parser found a processing instruction.
        case processingInstruction(target: String, data: String?)

        /// Event parser generated a warning during parsing.
        case warning(message: String)

        /// Event parser generated an error during parsing.
        case error(message: String)
    }

    public enum Error: Swift.Error {
        case unknown
        case unsupportedCharEncoding
        case stringEncodingConversion
        case emptyDocument
        case parsingFailure(location: Location, message: String)
    }

    public typealias EventHandler = (HTMLSAXParseContext, Event) -> Void

    /// The parse options the html parser was initialised with.
    open let parseOptions: ParseOptions

    public init(parseOptions: ParseOptions = .`default`) {
        self.parseOptions = parseOptions
    }

    /**
     Parse a string containing HTML content, calling the events on the handler
     supplied. Despite the handler being marked as escaping the parse method will
     operate synchronously.
     
     Note that your handler should not retain references to the HTMLSAXParseContext
     instance passed to it beyond the scope of the call. Additionally you should only
     access the HTMLSAXParseContext instance from the dispatch queue that called your
     event handler closure.
     
     - Parameter string: The string containing the HTML content.
     - Parameter handler: The event handler closure that will be called during parsing.
     - Throws: `HTMLParser.Error` if a fatal error occured during parsing.
     */
    open func parse(string: String, handler: @escaping EventHandler) throws {
        guard let uft8Data = string.data(using: .utf8) else {
            throw Error.stringEncodingConversion
        }

        try parse(data: uft8Data, encoding: .utf8, handler: handler)
    }

    /**
     Parse a data representation of HTML content, calling the events on the handler
     supplied. The data will be interpreted using the encoding if supplied. If no
     encoding is given then the parser will attempt to detect the encoding. Despite
     the handler being marked as escaping the parse method will operate synchronously.
     
     Note that your handler should not retain references to the HTMLSAXParseContext
     instance passed to it beyond the scope of the call. Additionally you should only
     access the HTMLSAXParseContext instance from the dispatch queue that called your
     event handler closure.
     
     - Parameter data: The data containing the HTML content.
     - Parameter encoding: The character encoding to interpret the data. If no encoding
     is given then the parser will attempt to detect the encoding.
     - Parameter handler: The event handler closure that will be called during parsing.
     - Throws: `HTMLParser.Error` if a fatal error occured during parsing.
     */
    open func parse(data: Data, encoding: String.Encoding? = nil, handler: @escaping EventHandler) throws {
        let dataLength = data.count

        guard dataLength > 0 else {
            // libxml2 will not parse zero length data
            throw Error.emptyDocument
        }

        try _parse(data: data, encoding: encoding, handler: handler)
    }

}
