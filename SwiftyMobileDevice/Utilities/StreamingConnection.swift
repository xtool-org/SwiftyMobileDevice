//
//  StreamingConnection.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 28/04/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

import Foundation

/// Represents a connection using a streaming protocol such as TCP
public protocol StreamingConnection {
    associatedtype Error: CAPIError

    associatedtype Raw
    var raw: Raw { get }

    var sendFunc: SendFunc { get }
    var receiveFunc: ReceiveFunc { get }
    var receiveTimeoutFunc: ReceiveTimeoutFunc { get }
}

extension StreamingConnection {

    public typealias SendFunc = (
        Raw, UnsafePointer<Int8>, UInt32, UnsafeMutablePointer<UInt32>
    ) -> Error.Raw

    public typealias ReceiveFunc = (
        Raw, UnsafeMutablePointer<Int8>, UInt32, UnsafeMutablePointer<UInt32>
    ) -> Error.Raw

    public typealias ReceiveTimeoutFunc = (
        Raw, UnsafeMutablePointer<Int8>, UInt32, UnsafeMutablePointer<UInt32>, UInt32
    ) -> Error.Raw

    /// - Returns: the number of bytes sent
    public func send(_ data: Data) throws -> Int {
        var sent: UInt32 = 0
        try data.withUnsafeBytes { bytes in
            let bound = bytes.bindMemory(to: Int8.self)
            try CAPI<Error>.check(
                sendFunc(raw, bound.baseAddress!, .init(bound.count), &sent)
            )
        }
        return .init(sent)
    }

    private func receiveRaw(
        data: UnsafeMutablePointer<Int8>, received: inout UInt32,
        maxLength: Int, timeout: TimeInterval?
    ) -> Error.Raw {
        timeout.map {
            receiveTimeoutFunc(
                raw, data, .init(maxLength), &received, .init($0 * 1000)
            )
        } ?? receiveFunc(raw, data, .init(maxLength), &received)
    }

    public func receive(maxLength: Int, timeout: TimeInterval? = nil) throws -> Data {
        try CAPI<Error>.getData(maxLength: maxLength) {
            receiveRaw(data: $0, received: &$1, maxLength: maxLength, timeout: timeout)
        }
    }

    /// receive all data until the end of the stream
    public func receiveAll(bufferSize: Int = 64 << 10, timeout: TimeInterval? = nil) throws -> Data {
        let buf = UnsafeMutablePointer<Int8>.allocate(capacity: bufferSize)
        defer { buf.deallocate() }
        var received: UInt32 = 0
        var data = Data()

        repeat {
            try CAPI<Error>.check(
                receiveRaw(data: buf, received: &received, maxLength: bufferSize, timeout: timeout)
            )
            buf.withMemoryRebound(to: UInt8.self, capacity: bufferSize) { ptr in
                data.append(ptr, count: .init(received))
            }
        } while received == bufferSize

        return data
    }

}
