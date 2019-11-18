//
//  CAPIWrapper.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 13/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation

public enum CAPIError: Error {
    case unexpectedNil
}

public protocol CAPIWrapperError: Swift.Error {
    associatedtype Raw
    init?(_ raw: Raw)
}

public protocol CAPIWrapper: class {
    associatedtype Error: CAPIWrapperError
    associatedtype Raw
    var raw: Raw { get }
}

extension CAPIWrapper {

    static func check(_ fn: @autoclosure () -> Error.Raw) throws {
        if let error = Error(fn()) { throw error }
    }

    static func getArrayWithCount(
        parseFn: (inout UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, inout Int32) -> Error.Raw,
        freeFn: (UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) -> Void
    ) throws -> [String]? {
        var rawValues: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?
        var count: Int32 = 0
        try check(parseFn(&rawValues, &count))
        guard let values = rawValues else { return nil }

        defer { freeFn(values) }

        return UnsafeBufferPointer(start: values, count: Int(count))
            .compactMap { $0 }
            .map { String(cString: $0) }
    }

    static func getNullTerminatedArray(
        parseFn: (inout UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Error.Raw,
        freeFn: (UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) -> Void
    ) throws -> [String] {
        var rawValues: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?
        try Self.check(parseFn(&rawValues))
        guard let values = rawValues else { throw CAPIError.unexpectedNil }

        defer { freeFn(values) }

        return sequence(state: values) { (
            info: inout UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>
        ) -> UnsafeMutablePointer<Int8>? in
            defer { info += 1 }
            return info.pointee
        }.map { String(cString: $0) }
    }

    static func getDictionary(
        parseFn: (inout UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Error.Raw,
        freeFn: (UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) -> Void
    ) throws -> [String: String] {
        let strings = try getNullTerminatedArray(parseFn: parseFn, freeFn: freeFn)
        return Dictionary(
            uniqueKeysWithValues: stride(from: 0, to: strings.count, by: 2).map {
                (strings[$0], strings[$0 + 1])
            }
        )
    }

    static func getData(
        maxLength: Int,
        parseFn: (UnsafeMutablePointer<Int8>, inout UInt32) -> Error.Raw
    ) throws -> Data {
        let data = UnsafeMutablePointer<Int8>.allocate(capacity: maxLength)
        defer { data.deallocate() }
        var received: UInt32 = 0

        try check(parseFn(data, &received))

        return Data(bytes: data, count: .init(received))
    }

}

struct CAPIHelpers {

}
