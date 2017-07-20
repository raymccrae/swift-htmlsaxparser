//
//  HTMLParser.swift
//  HTMLParser
//
//  Created by Raymond Mccrae on 20/07/2017.
//  Copyright © 2017 Raymond Mccrae.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import libxml2

open class HTMLParser {
    
    public struct Location {
        let line: Int
        let column: Int
    }
    
    public typealias LocationClosure = () -> Location
    
    public enum Event {
        case startDocument(location: LocationClosure)
        case endDocument(location: LocationClosure)
        case startElement(name: String, attributes: [String: String], location: LocationClosure)
        case endElement(location: LocationClosure)
        case characters(characters: String, location: LocationClosure)
        case comment(comment: String, location: LocationClosure)
        case cdata(block: Data, location: LocationClosure)
        case processingInstruction(target: String, data: String?, location: LocationClosure)
    }
    
    public enum Error: Swift.Error {
        case unknown
        case unsupportedCharEncoding
        case stringEncodingConversion
        case emptyDocument
    }
    
    public typealias EventHandler = (Event) -> Void
    
    open func parse(string: String, handler: @escaping EventHandler) throws {
        guard let uft8Data = string.data(using: .utf8) else {
            throw Error.stringEncodingConversion
        }
        
        try parse(data: uft8Data, encoding: .utf8, handler: handler)
    }
    
    open func parse(data: Data, encoding: String.Encoding? = nil, handler: @escaping EventHandler) throws {
        let dataLength = data.count
        
        guard dataLength > 0 else {
            // libxml2 will not parse zero length data
            throw Error.emptyDocument
        }
        
        var charEncoding: xmlCharEncoding = XML_CHAR_ENCODING_NONE

        try data.withUnsafeBytes { (dataBytes: UnsafePointer<UInt8>) -> Void in
            
            if let encoding = encoding {
                charEncoding = convert(from: encoding)
            }
            else {
                charEncoding = xmlDetectCharEncoding(dataBytes, Int32(dataLength))
            }
            
            guard charEncoding != XML_CHAR_ENCODING_NONE && charEncoding != XML_CHAR_ENCODING_ERROR else {
                throw Error.unsupportedCharEncoding
            }
        }
        
        try data.withUnsafeBytes{ (dataBytes: UnsafePointer<Int8>) -> Void in
            let handlerContext = HandlerContext(handler: handler)
            let handlerContextPtr = Unmanaged<HandlerContext>.passUnretained(handlerContext).toOpaque()
            guard let parserContext = htmlCreatePushParserCtxt(&saxHandler, handlerContextPtr, dataBytes, Int32(dataLength), nil, charEncoding) else {
                throw Error.unknown
            }
            handlerContext.contextPtr = parserContext
            
            htmlCtxtUseOptions(parserContext, Int32(HTML_PARSE_RECOVER.rawValue) | Int32(HTML_PARSE_NONET.rawValue) | Int32(HTML_PARSE_COMPACT.rawValue) | Int32(HTML_PARSE_NOBLANKS.rawValue) | Int32(HTML_PARSE_NOIMPLIED.rawValue))
            
            let _ = htmlParseDocument(parserContext)
        }
        
    }
    
    func convert(from swiftEncoding: String.Encoding) -> xmlCharEncoding {
        switch swiftEncoding {
        case .utf8:
            return XML_CHAR_ENCODING_UTF8
        case .utf16LittleEndian:
            return XML_CHAR_ENCODING_UTF16LE
        case .utf16BigEndian:
            return XML_CHAR_ENCODING_UTF16BE
        case .isoLatin1:
            return XML_CHAR_ENCODING_8859_1
        case .isoLatin2:
            return XML_CHAR_ENCODING_8859_2
            
        default:
            return XML_CHAR_ENCODING_NONE
        }
    }
    
    private class HandlerContext {
        let handler: EventHandler
        var contextPtr: htmlParserCtxtPtr?
        
        init(handler: @escaping EventHandler) {
            self.handler = handler
        }
        
        func location() -> Location {
            guard let contextPtr = contextPtr else {
                return Location(line: 0, column: 0)
            }
            let lineNumber = Int(xmlSAX2GetLineNumber(contextPtr))
            let columnNumber = Int(xmlSAX2GetColumnNumber(contextPtr))
            let loc = Location(line: lineNumber, column: columnNumber)
            return loc
        }
    }
    
    private lazy var saxHandler: htmlSAXHandler = {
        var handler = htmlSAXHandler()
//        handler.internalSubset = nil
//        handler.isStandalone = nil
//        handler.hasInternalSubset = nil
//        handler.hasExternalSubset = nil
//        handler.resolveEntity = nil
//        handler.getEntity = nil
//        handler.entityDecl = nil
//        handler.notationDecl = nil
//        handler.attributeDecl = nil
//        handler.elementDecl = nil
//        handler.unparsedEntityDecl = nil
//        handler.setDocumentLocator = nil
        handler.startDocument = { (context: UnsafeMutableRawPointer?) in
            guard let context = context else {
                return
            }
            
            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            handlerContext.handler(.startDocument(location: handlerContext.location))
        }
        
        handler.endDocument = { (context: UnsafeMutableRawPointer?) in
            guard let context = context else {
                return
            }
            
            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            handlerContext.handler(.endDocument(location: handlerContext.location))
        }
        handler.startElement = { (context: UnsafeMutableRawPointer?,
                                  name: UnsafePointer<UInt8>?,
                                  attrs: UnsafeMutablePointer<UnsafePointer<UInt8>?>?) in
            guard let context = context, let name = name else {
                return
            }
            
            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            let elementName = String(cString: name)
            var elementAttributes: [String: String] = [:]
            
            if let attrs = attrs {
                var attrPtr = attrs.advanced(by: 0)
                
                while true {
                    let attrName = attrPtr.pointee
                    if let attrName = attrName {
                        let attributeName = String(cString: attrName)
                        attrPtr = attrPtr.advanced(by: 1)
                        
                        if let attrValue = attrPtr.pointee {
                            let attributeValue = String(cString: attrValue)
                            elementAttributes[attributeName] = attributeValue
                        }
                        else {
                            elementAttributes[attributeName] = ""
                        }
                    }
                    else {
                        break
                    }
                    
                    
                }
            }
            
            handlerContext.handler(.startElement(name: elementName,
                                                 attributes: elementAttributes,
                                                 location: handlerContext.location))
        }
//        handler.endElement = nil
//        handler.reference = nil
//        handler.characters = nil
//        handler.ignorableWhitespace = nil
        handler.processingInstruction = nil
//        handler.
        
        return handler
    }()
}
