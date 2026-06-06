//
//  Base32Tests.swift
//  Base32
//
//  Created by 野村 憲男 on 1/24/15.
//
//  Copyright (c) 2015 Norio Nomura
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import Testing
@testable import VaultCore

struct Base32Tests {
    let vectors: [(String, String, String)] = [
        ("", "", ""),
        ("f", "MY======", "CO======"),
        ("fo", "MZXQ====", "CPNG===="),
        ("foo", "MZXW6===", "CPNMU==="),
        ("foob", "MZXW6YQ=", "CPNMUOG="),
        ("fooba", "MZXW6YTB", "CPNMUOJ1"),
        ("foobar", "MZXW6YTBOI======", "CPNMUOJ1E8======"),
    ]

    // MARK: https://tools.ietf.org/html/rfc4648

    @Test
    func RFC4648_base32Encode() {
        let convertedVectors = vectors.map { ($0.dataUsingUTF8StringEncoding, $1, $2) }
        for (test, expect, _) in convertedVectors {
            #expect(base32Encode(test) == expect, "base32Encode for \(test)")
        }
    }

    @Test
    func RFC4648_base32Decode() throws {
        let convertedVectors = vectors.map { ($0.dataUsingUTF8StringEncoding, $1, $2) }
        for (expect, test, _) in convertedVectors {
            let result = try base32DecodeToData(test)
            #expect(result == expect, "base32Decode for \(test)")
        }
    }

    @Test
    func RFC4648_base32HexEncode() {
        let convertedVectors = vectors.map { ($0.dataUsingUTF8StringEncoding, $1, $2) }
        for (test, _, expectHex) in convertedVectors {
            #expect(base32HexEncode(test) == expectHex, "base32HexEncode for \(test)")
        }
    }

    @Test
    func RFC4648_base32HexDecode() throws {
        let convertedVectors = vectors.map { ($0.dataUsingUTF8StringEncoding, $1, $2) }
        for (expect, _, testHex) in convertedVectors {
            let resultHex = try base32HexDecodeToData(testHex)
            #expect(resultHex == expect, "base32HexDecode for \(testHex)")
        }
    }

    // MARK: -

    @Test
    func base32ExtensionString() throws {
        for (test, expect, expectHex) in vectors {
            let result = test.base32EncodedString
            let resultHex = test.base32HexEncodedString
            #expect(result == expect, "\(test).base32EncodedString")
            #expect(resultHex == expectHex, "\(test).base32HexEncodedString")
            let decoded = try result.base32DecodedString()
            let decodedHex = try resultHex.base32HexDecodedString()
            #expect(decoded == test, "\(result).base32DecodedString()")
            #expect(decodedHex == test, "\(resultHex).base32HexDecodedString()")
        }
    }

    @Test
    func base32ExtensionData() throws {
        let dataVectors = vectors.map {
            (
                $0.dataUsingUTF8StringEncoding,
                $1.dataUsingUTF8StringEncoding,
                $2.dataUsingUTF8StringEncoding,
            )
        }
        for (test, expect, expectHex) in dataVectors {
            let result = test.base32EncodedData
            let resultHex = test.base32HexEncodedData
            #expect(result == expect, "\(test).base32EncodedData")
            #expect(resultHex == expectHex, "\(test).base32HexEncodedData")
            let decoded = try result.base32DecodedData
            let decodedHex = try resultHex.base32HexDecodedData
            #expect(decoded == test, "\(result).base32DecodedData")
            #expect(decodedHex == test, "\(resultHex).base32HexDecodedData")
        }
    }

    @Test
    func base32ExtensionDataAndString() throws {
        let dataAndStringVectors = vectors.map { ($0.dataUsingUTF8StringEncoding, $1, $2) }
        for (test, expect, expectHex) in dataAndStringVectors {
            let result = test.base32EncodedString
            let resultHex = test.base32HexEncodedString
            #expect(result == expect, "\(test).base32EncodedString")
            #expect(resultHex == expectHex, "\(test).base32HexEncodedString")
            let decoded = try result.base32DecodedData
            let decodedHex = try resultHex.base32HexDecodedData
            #expect(decoded == test, "\(result).base32DecodedData")
            #expect(decodedHex == test, "\(resultHex).base32HexDecodedData")
        }
    }

    // MARK: -

    @Test
    func base32DecodeStringAcceptableLengthPatterns() throws {
        // "=" stripped valid string
        let strippedVectors = vectors.map {
            (
                $0.dataUsingUTF8StringEncoding,
                $1.replacingOccurrences(of: "=", with: ""),
                $2.replacingOccurrences(of: "=", with: ""),
            )
        }
        for (expect, test, testHex) in strippedVectors {
            let result = try base32DecodeToData(test)
            let resultHex = try base32HexDecodeToData(testHex)
            #expect(result == expect, "base32Decode for \(test)")
            #expect(resultHex == expect, "base32HexDecode for \(testHex)")
        }

        // invalid length string with padding
        let invalidVectorWithPaddings: [(String, String)] = [
            ("M=======", "C======="),
            ("MYZ=====", "COZ====="),
            ("MZXW6Z==", "CPNMUZ=="),
            ("MZXW6YTBO=======", "CPNMUOJ1E======="),
        ]
        for (test, testHex) in invalidVectorWithPaddings {
            #expect(throws: (any Error).self) { try base32DecodeToData(test) }
            #expect(throws: (any Error).self) { try base32HexDecodeToData(testHex) }
        }

        // invalid length string without padding
        let invalidVectorWithoutPaddings = invalidVectorWithPaddings.map {
            (
                $0.replacingOccurrences(of: "=", with: ""),
                $1.replacingOccurrences(of: "=", with: ""),
            )
        }
        for (test, testHex) in invalidVectorWithoutPaddings {
            #expect(throws: (any Error).self) { try base32DecodeToData(test) }
            #expect(throws: (any Error).self) { try base32HexDecodeToData(testHex) }
        }
    }

    @Test
    func base32Decode() {
        let b32 = "AY22KLPRBYJXNH6TRM4I3LPBYA======"
        #expect(throws: Never.self, performing: {
            _ = try b32.base32DecodedData
        })
    }
}
