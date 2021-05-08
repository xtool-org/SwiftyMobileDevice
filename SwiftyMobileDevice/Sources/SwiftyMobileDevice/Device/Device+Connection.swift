//
//  Device+Connection.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 28/04/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

import Foundation
import libimobiledevice

extension Device {

    public class Connection: StreamingConnection {

        public typealias Error = Device.Error
        public typealias Raw = idevice_connection_t

        public let raw: idevice_connection_t
        public init(raw: idevice_connection_t) { self.raw = raw }
        public init(device: Device, port: UInt16) throws {
            var connection: idevice_connection_t?
            try CAPI<Error>.check(idevice_connect(device.raw, port, &connection))
            guard let raw = connection else { throw Error.internal }
            self.raw = raw
        }
        deinit { idevice_disconnect(raw) }

        /// - Warning: The file handle returned is only valid while the `Connection` instance
        /// exists
        public func fileHandle() throws -> FileHandle {
            var handle: Int32 = 0
            try CAPI<Error>.check(idevice_connection_get_fd(raw, &handle))
            return FileHandle(fileDescriptor: handle)
        }

        public let sendFunc: SendFunc = idevice_connection_send
        public let receiveFunc: ReceiveFunc = idevice_connection_receive
        public let receiveTimeoutFunc: ReceiveTimeoutFunc = idevice_connection_receive_timeout

        public func setSSLEnabled(_ enabled: Bool) throws {
            try CAPI<Error>.check(
                (enabled ? idevice_connection_enable_ssl: idevice_connection_disable_ssl)(raw)
            )
        }

    }

    public func connect(to port: UInt16) throws -> Connection {
        try Connection(device: self, port: port)
    }

}
