//
//  PlistNodeCoders.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 13/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation

class PlistNodeEncoder {
    enum Error: Swift.Error {
        case failedToEncode
    }

    private let encoder: PropertyListEncoder
    var userInfo: [CodingUserInfoKey: Any] {
        get { encoder.userInfo }
        set { encoder.userInfo = newValue }
    }

    init() {
        encoder = PropertyListEncoder()
        // binary is more efficient than xml
        encoder.outputFormat = .binary
    }

    func encode<V: Encodable>(_ value: V) throws -> plist_t {
        var node: plist_t?
        let data = try encoder.encode(value)
        data.withUnsafeBytes { bytes in
            let bound = bytes.bindMemory(to: Int8.self)
            plist_from_bin(bound.baseAddress, .init(bound.count), &node)
        }
        return try node.orThrow(Error.failedToEncode)
    }

    @discardableResult func withEncoded<V: Encodable, T>(_ value: V, block: (plist_t) throws -> T) throws -> T {
        let raw = try encode(value)
        defer { plist_free(raw) }
        return try block(raw)
    }
}

class PlistNodeDecoder {
    enum Error: Swift.Error {
        case failedToDecode
        case acceptorFailed
    }

    private let decoder: PropertyListDecoder
    var userInfo: [CodingUserInfoKey: Any] {
        get { decoder.userInfo }
        set { decoder.userInfo = newValue }
    }

    init() {
        decoder = PropertyListDecoder()
    }

    // doesn't take ownership
    func decode<T: Decodable>(_ type: T.Type, from plist: plist_t) throws -> T {
        var buf: UnsafeMutablePointer<Int8>?
        var length: UInt32 = 0
        plist_to_bin(plist, &buf, &length)
        let data = Data(bytes: try buf.orThrow(Error.failedToDecode), count: .init(length))
        return try decoder.decode(type, from: data)
    }

    func decode<T: Decodable>(_ type: T.Type, acceptor: (inout plist_t?) throws -> Void) throws -> T {
        var raw: plist_t?
        try acceptor(&raw)
        let node = try raw.orThrow(Error.acceptorFailed)
        defer { plist_free(raw) }
        return try decode(type, from: node)
    }
}
