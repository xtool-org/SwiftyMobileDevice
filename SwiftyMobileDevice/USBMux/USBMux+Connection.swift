//
//  USBMux+Connection.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 11/04/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

import Foundation
import usbmuxd

extension USBMux {

    public class Connection: StreamingConnection {

        public typealias Error = USBMux.Error
        public typealias Raw = Int32

        public let raw: Int32
        public init(raw: Int32) {
            self.raw = raw
        }
        public init(handle: Device.Handle, port: UInt16) throws {
            let ret = usbmuxd_connect(handle.raw, port)
            try CAPI<Error>.check(ret)
            self.raw = ret
        }
        deinit { usbmuxd_disconnect(raw) }

        public let sendFunc: SendFunc = usbmuxd_send
        public let receiveFunc: ReceiveFunc = usbmuxd_recv
        public let receiveTimeoutFunc: ReceiveTimeoutFunc = usbmuxd_recv_timeout

    }

    public static func connect(withHandle handle: Device.Handle, port: UInt16) throws -> Connection {
        try Connection(handle: handle, port: port)
    }

}
