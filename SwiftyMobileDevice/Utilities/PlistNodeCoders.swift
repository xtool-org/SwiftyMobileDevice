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

    /*
    private func convert(serialized: Any) -> plist_t? {
        switch serialized {
        case let value as Bool:
            return plist_new_bool(value ? 1 : 0)
        case let value as UInt64:
            return plist_new_uint(value)
        case let value as Double:
            return plist_new_real(value)
        case let value as String:
            return plist_new_string(value)
        case let value as [Any]:
            guard let node = plist_new_array()
                else { return nil }
            for element in value {
                guard let converted = convert(serialized: element)
                    else { return nil }
                plist_array_append_item(node, converted)
            }
            return node
        case let value as [String: Any]:
            guard let node = plist_new_dict()
                else { return nil }
            for (key, val) in value {
                guard let converted = convert(serialized: val)
                    else { return nil }
                plist_dict_set_item(node, key, converted)
            }
            return node
        case let value as Date:
            let time = value.timeIntervalSinceReferenceDate
            let seconds = Int32(time)
            let remainder = time - TimeInterval(seconds)
            let usec = Int32(remainder * 1_000_000)
            return plist_new_date(seconds, usec)
        case let value as Data:
            return value.withUnsafeBytes { buf in
                let bound = buf.bindMemory(to: Int8.self)
                return plist_new_data(bound.baseAddress!, UInt64(bound.count))
            }
        default:
            return nil
        }
    }

    // the caller is responsible for freeing the returned plist with `plist_free`
    func encode<V: Encodable>(_ value: V) throws -> plist_t {
        // we need to embed value in an array/dict, because those are the only permitted objects
        // at the top level
        let data = try encoder.encode([value])

        guard let array = try PropertyListSerialization.propertyList(from: data, format: nil) as? [Any],
            array.count == 1
            else { throw Error.failedToEncode }

        return try convert(serialized: array[0]).orThrow(Error.failedToEncode)
    }

    @discardableResult func withEncoded<V: Encodable, T>(_ value: V, block: (plist_t) throws -> T) throws -> T {
        let raw = try encode(value)
        defer { plist_free(raw) }
        return try block(raw)
    }
 */

    // the lifetime of the plist is scoped to `block`. The callee manages this.
    @discardableResult func withEncoded<V: Encodable, T>(_ value: V, block: (plist_t) throws -> T) throws -> T {
        // we need to embed value in an array/dict, because those are the only permitted objects
        // at the top level
        let data = try encoder.encode([value])

        var optionalArray: plist_t?
        data.withUnsafeBytes { buf in
            let bound = buf.bindMemory(to: Int8.self)
            plist_from_bin(bound.baseAddress!, UInt32(bound.count), &optionalArray)
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

    /*
    private func serialize(node: plist_t) -> Any? {
        switch plist_get_node_type(node) {
        case PLIST_BOOLEAN:
            var value: UInt8 = 0
            plist_get_bool_val(node, &value)
            return value != 0
        case PLIST_UINT:
            var value: UInt64 = 0
            plist_get_uint_val(node, &value)
            return value
        case PLIST_REAL:
            var value: Double = 0
            plist_get_real_val(node, &value)
            return value
        case PLIST_STRING:
            return try? CAPI<CAPINoError>.getString { plist_get_string_val(node, &$0) }
        case PLIST_ARRAY:
            let size = plist_array_get_size(node)
            var array: [Any] = []
            for idx in 0..<size {
                guard let item = plist_array_get_item(node, idx),
                    let serialized = serialize(node: item)
                    else { return nil }
                array.append(serialized)
            }
            return array
        case PLIST_DICT:
            var optionalIter: plist_dict_iter?
            plist_dict_new_iter(node, &optionalIter)
            guard let iter = optionalIter else { return nil }
            var dict: [String: Any] = [:]
            var currVal: plist_t?
            while true {
                guard let string = try? CAPI<CAPINoError>.getString(parseFn: {
                    plist_dict_next_item(node, iter, &$0, &currVal)
                }), let val = currVal, let serialized = serialize(node: val) else { break }
                dict[string] = serialized
            }
            return dict
        case PLIST_DATE:
            var sec: Int32 = 0
            var usec: Int32 = 0
            plist_get_date_val(node, &sec, &usec)
            return Date(timeIntervalSinceReferenceDate: Double(sec) + Double(usec) / 1_000_000)
        case PLIST_DATA:
            return try? CAPI<CAPINoError>.getData { buf, len in
                var lenProxy: UInt64 {
                    get { UInt64(len) }
                    set { len = UInt32(newValue) }
                }
                return plist_get_data_val(node, &buf, &lenProxy)
            }
        default:
            return nil
        }
    }

    func decode<T: Decodable>(_ type: T.Type, from node: plist_t) throws -> T {
        let serialized = [try serialize(node: node).orThrow(Error.failedToDecode)]
        let data = try PropertyListSerialization.data(fromPropertyList: serialized, format: .binary, options: 0)

        let decoded = try decoder.decode([T].self, from: data)
        guard decoded.count == 1 else { throw Error.failedToDecode }
        return decoded[0]
    }

    func decode<T: Decodable>(_ type: T.Type, acceptor: (inout plist_t?) throws -> Void) throws -> T {
        var raw: plist_t?
        try acceptor(&raw)
        let node = try raw.orThrow(Error.acceptorFailed)
        defer { plist_free(raw) }
        return try decode(type, from: node)
    }
 */

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
