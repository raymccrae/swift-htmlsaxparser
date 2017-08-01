//
//  HTMLSAXParser+libxml2.swift
//  HTMLSAXParser
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

import Foundation
import libxml2
import HTMLParserC

internal extension HTMLSAXParser {
    
    func _parse(data: Data, encoding: String.Encoding?, handler: @escaping EventHandler) throws {
        let dataLength = data.count
        var charEncoding: xmlCharEncoding = XML_CHAR_ENCODING_NONE

        if let encoding = encoding {
            charEncoding = convert(from: encoding)
        }
        else {
            data.withUnsafeBytes { (dataBytes: UnsafePointer<UInt8>) -> Void in
                charEncoding = xmlDetectCharEncoding(dataBytes, Int32(dataLength))
            }
        }

        guard charEncoding != XML_CHAR_ENCODING_NONE && charEncoding != XML_CHAR_ENCODING_ERROR else {
            throw Error.unsupportedCharEncoding
        }
        
        try data.withUnsafeBytes{ (dataBytes: UnsafePointer<Int8>) -> Void in
            let handlerContext = HandlerContext(handler: handler)
            let handlerContextPtr = Unmanaged<HandlerContext>.passUnretained(handlerContext).toOpaque()
            var libxmlHandler = saxHandler()
            guard let parserContext = htmlCreatePushParserCtxt(&libxmlHandler, handlerContextPtr, dataBytes, Int32(dataLength), nil, charEncoding) else {
                throw Error.unknown
            }
            defer {
                // Free the parser context when we exit the scope.
                htmlFreeParserCtxt(parserContext)
                handlerContext.contextPtr = nil
            }
            
            handlerContext.contextPtr = parserContext
            let options = CInt(parseOptions.rawValue)
            htmlCtxtUseOptions(parserContext, options)
            
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
    
    private func saxHandler() -> htmlSAXHandler {
        var handler = htmlSAXHandler()
        
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
        
        handler.endElement = { (context, name) in
            guard let context = context, let name = name else {
                return
            }

            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            let elementName = String(cString: name)

            handlerContext.handler(.endElement(name: elementName,
                                               location: handlerContext.location))
        }
        
        handler.characters = { (context, characters, length) in
            guard let context = context, let characters = characters else {
                return
            }

            let ptr = UnsafeMutableRawPointer(OpaquePointer(characters))
            let data = Data(bytesNoCopy: ptr,
                            count: Int(length),
                            deallocator: .none)
            guard let text = String(data: data, encoding: .utf8) else {
                return
            }

            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            handlerContext.handler(.characters(text: text,
                                               location: handlerContext.location))
            
        }

        handler.processingInstruction = { (context, target, data) in
            guard let context = context, let target = target else {
                return
            }

            let targetString = String(cString: target)
            let dataString: String?
            if let data = data {
                dataString = String(cString: data)
            }
            else {
                dataString = nil
            }

            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            handlerContext.handler(.processingInstruction(target: targetString,
                                                          data: dataString,
                                                          location: handlerContext.location))
        }

        handler.comment = { (context, comment) in
            guard let context = context, let comment = comment else {
                return
            }

            let commentString = String(cString: comment)
            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            handlerContext.handler(.comment(text: commentString,
                                            location: handlerContext.location))
        }

        handler.cdataBlock = { (context, block, length) in
            guard let context = context, let block = block else {
                return
            }

            let dataBlock = Data(bytes: block, count: Int(length))
            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            handlerContext.handler(.cdata(block: dataBlock,
                                          location: handlerContext.location))
        }
        
        let _ = HTMLSAXParser.globalErrorHandler
        let _ = HTMLSAXParser.globalWarningHandler
        withUnsafeMutablePointer(to: &handler) { (handlerPtr) in
            htmlparser_set_global_error_handler(handlerPtr)
            htmlparser_set_global_warning_handler(handlerPtr)
        }

        return handler
    }

    private static var globalErrorHandler: HTMLParserWrappedErrorSAXFunc = {
        htmlparser_global_error_sax_func = {context, message in
            guard let context = context, let message = message else {
                return
            }

            let messageString = String(cString: message).trimmingCharacters(in: .whitespacesAndNewlines)
            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            handlerContext.handler(.error(message: messageString,
                                          location: handlerContext.location))
        }
        return htmlparser_global_error_sax_func
    }()
    private static var globalWarningHandler: HTMLParserWrappedWarningSAXFunc = {
        htmlparser_global_warning_sax_func = { context, message in
            guard let context = context, let message = message else {
                return
            }

            let messageString = String(cString: message).trimmingCharacters(in: .whitespacesAndNewlines)
            let handlerContext: HandlerContext = Unmanaged<HandlerContext>.fromOpaque(context).takeUnretainedValue()
            handlerContext.handler(.warning(message: messageString,
                                            location: handlerContext.location))
        }
        return htmlparser_global_warning_sax_func
    }()
}
