//
//  USBMux+Connection.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 11/04/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

import Foundation

extension USBMux {

    public class Connection {
        public let raw: Int32

        public init(raw: Int32) {
            self.raw = raw
        }
        public init(handle: Device.Handle, port: UInt16) throws {
            let ret = usbmuxd_connect(handle.raw, port)
            guard ret >= 0 else { throw Error.errno(.init(ret)) }
            self.raw = ret
        }
        deinit { usbmuxd_disconnect(raw) }

        public func send(_ data: Data) throws -> Int {
            try data.withUnsafeBytes { bytes in
                var sent: UInt32 = 0
                let bound = bytes.bindMemory(to: Int8.self)
                try USBMux.check(usbmuxd_send(raw, bound.baseAddress!, .init(bound.count), &sent))
                return Int(sent)
            }
        }

        public func receive(maxLength: Int, timeout: TimeInterval? = nil) throws -> Data {
            try Data([UInt8](unsafeUninitializedCapacity: maxLength) { buf, received in
                var receivedBytes: UInt32 = 0
                try USBMux.check(buf.withMemoryRebound(to: Int8.self) { buf in
                    timeout.map {
                        usbmuxd_recv_timeout(raw, buf.baseAddress!, .init(buf.count), &receivedBytes, .init($0 * 1000))
                    } ?? usbmuxd_recv(raw, buf.baseAddress!, .init(buf.count), &receivedBytes)
                })
                received = .init(receivedBytes)
            })
        }
    }

    public static func connect(withHandle handle: Device.Handle, port: UInt16) throws -> Connection {
        try Connection(handle: handle, port: port)
    }

}
