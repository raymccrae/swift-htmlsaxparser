//
//  EscapeSpecialCharacters.swift
//  HTMLSAXParser
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

import Foundation
import CHTMLSAXParser

public enum HTMLQuoteCharacter: Character {
    case none = "\0"
    case singleQuote = "'"
    case doubleQuote = "\""
    
    var characterCode: CInt {
        switch self {
        case .none:
            return 0
        case .singleQuote:
            return 39
        case .doubleQuote:
            return 34
        }
    }
}

public extension Data {
    
    public func encodeHTMLEntities(quoteCharacter: HTMLQuoteCharacter = .doubleQuote) -> Data? {
        let bufferGrowthFactor = 1.4
        let inputLength = self.count
        var outputLength = Int(Double(inputLength) * bufferGrowthFactor)

        var inputLengthBytes = UnsafeMutablePointer<CInt>.allocate(capacity: 1)
        var outputLengthBytes = UnsafeMutablePointer<CInt>.allocate(capacity: 1)
        defer {
            inputLengthBytes.deallocate(capacity: 1)
            outputLengthBytes.deallocate(capacity: 1)
        }
        
        var loop = true

        repeat {
            inputLengthBytes.pointee = CInt(inputLength)
            outputLengthBytes.pointee = CInt(outputLength)

            let outputData = self.withUnsafeBytes { (inputBytes: UnsafePointer<UInt8>) -> Data? in
                let outputBufferCapacity = outputLength
                let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outputBufferCapacity)
                defer {
                    outputBuffer.deallocate(capacity: Int(outputBufferCapacity))
                }
                let result = htmlEncodeEntities(outputBuffer, outputLengthBytes, inputBytes, inputLengthBytes, quoteCharacter.characterCode)

                if result == 0 { // zero represents success
                    // Have we consumed the length of the input buffer
                    let consumed = inputLengthBytes.pointee
                    if consumed == inputLength {
                        loop = false
                        return Data(bytes: outputBuffer, count: Int(outputLengthBytes.pointee))
                    }
                    else {
                        // if we have not consumed the full input buffer.
                        // estimate a new output buffer length
                        let ratio = Double(consumed) / Double(inputLength)
                        outputLength = Int( (2.0 - ratio) * Double(outputLength) * bufferGrowthFactor )
                    }
                }
                else {
                    loop = false
                }

                return nil
            }

            if let outputData = outputData {
                return outputData
            }

        } while loop
        
        return nil
    }
}

public extension String {
    public func encodeHTMLEntities(quoteCharacter: HTMLQuoteCharacter = .doubleQuote) -> String? {
        guard let utf8Data = self.data(using: .utf8) else {
            return nil
        }
        guard let encoded = utf8Data.encodeHTMLEntities(quoteCharacter: quoteCharacter) else {
            return nil
        }
        return String(data: encoded, encoding: .utf8)
    }
}