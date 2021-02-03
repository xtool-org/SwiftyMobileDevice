//
//  PlistNodeCoders.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 13/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation
import plist

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

    // the lifetime of the plist is scoped to `block`. The callee manages this.
    @discardableResult func withEncoded<V: Encodable, T>(_ value: V, block: (plist_t) throws -> T) throws -> T {
        // we need to embed value in an array/dict, because those are the only permitted objects
        // at the top level
        let data = try encoder.encode([value])

        var optionalArray: plist_t?
        data.withUnsafeBytes { (buf: UnsafeRawBufferPointer) in
            let bound = buf.bindMemory(to: Int8.self)
            plist_from_bin(bound.baseAddress, UInt32(bound.count), &optionalArray)
        }

        guard let array = optionalArray,
            plist_array_get_size(array) == 1,
            let item = plist_array_get_item(array, 0)
            else { throw Error.failedToEncode }
        defer { plist_free(array) }

        return try block(item)
    }

    // the caller is responsible for freeing the returned plist with `plist_free`
    func encode<V: Encodable>(_ value: V) throws -> plist_t {
        try withEncoded(value) { plist_copy($0) }
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

    // takes ownership
    func decode<T: Decodable>(_ type: T.Type, moving node: plist_t) throws -> T {
        let array = plist_new_array()
        defer { plist_free(array) }
        // move ownership of `node` to `array`
        plist_array_append_item(array, node)

        let data = try CAPI<CAPINoError>.getData { plist_to_bin(array, &$0, &$1) }

        let decoded = try decoder.decode([T].self, from: data)
        guard decoded.count == 1 else { throw Error.failedToDecode }
        return decoded[0]
    }

    // takes ownership
    func decode<T: Decodable>(_ type: T.Type, acceptor: (inout plist_t?) throws -> Void) throws -> T {
        var raw: plist_t?
        try acceptor(&raw)
        let node = try raw.orThrow(Error.acceptorFailed)
        return try decode(type, moving: node)
    }

    // doesn't take ownership
    func decode<T: Decodable>(_ type: T.Type, from node: plist_t) throws -> T {
        try decode(type, moving: plist_copy(node))
    }

}
