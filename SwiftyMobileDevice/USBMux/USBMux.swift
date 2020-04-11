//
//  USBMux.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 11/04/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

import Foundation

public enum USBMux {

    public enum Error: LocalizedError {
        case errno(Int)

        public var errorDescription: String? {
            switch self {
            case .errno(let errnum):
                let str = strerror(.init(errnum))
                return String(cString: str!)
            }
        }
    }

    public enum ConnectionType {
        case usb
        case network

        public var raw: usbmux_connection_type {
            switch self {
            case .usb: return CONNECTION_TYPE_USB
            case .network: return CONNECTION_TYPE_NETWORK
            }
        }

        public init?(raw: usbmux_connection_type) {
            switch raw {
            case CONNECTION_TYPE_USB: self = .usb
            case CONNECTION_TYPE_NETWORK: self = .network
            default: return nil
            }
        }
    }

    public struct Device {
        public struct Handle {
            public let raw: UInt32
            public init(raw: UInt32) {
                self.raw = raw
            }
        }

        public let handle: Handle
        public let productID: UInt32
        public let udid: String
        public let connectionType: ConnectionType
        public let connectionData: Data

        init?(raw: usbmuxd_device_info_t) {
            self.handle = Handle(raw: raw.handle)

            self.productID = raw.product_id

            var udidRaw = raw.udid
            let udidBuf = UnsafeRawBufferPointer(start: &udidRaw.0, count: MemoryLayout.size(ofValue: udidRaw))
            guard let udid = String(bytes: udidBuf.bindMemory(to: UInt8.self), encoding: .utf8) else { return nil }
            self.udid = udid

            guard let connectionType = ConnectionType(raw: raw.conn_type) else { return nil }
            self.connectionType = connectionType

            var dataRaw = raw.conn_data
            self.connectionData = Data(bytes: &dataRaw.0, count: MemoryLayout.size(ofValue: dataRaw))
        }
    }

    static func check(_ result: Int32) throws {
        guard result == 0 else { throw Error.errno(.init(result)) }
    }

    public static func buid() throws -> String {
        var buidBytes: UnsafeMutablePointer<Int8>?
        try check(usbmuxd_read_buid(&buidBytes))
        defer { free(buidBytes) }
        return String(cString: buidBytes!)
    }

    public static func pairRecord(withID id: String) throws -> Data {
        var recordData: UnsafeMutablePointer<Int8>?
        var recordSize: UInt32 = 0
        try check(usbmuxd_read_pair_record(id, &recordData, &recordSize))
        defer { free(recordData) }
        return Data(bytes: recordData!, count: Int(recordSize))
    }

    public static func savePairRecord(_ record: Data, withID id: String, handle: Device.Handle? = nil) throws {
        try record.withUnsafeBytes { buf in
            let bound = buf.bindMemory(to: Int8.self)
            try check(
                usbmuxd_save_pair_record_with_device_id(id, handle?.raw ?? 0, bound.baseAddress, .init(bound.count))
            )
        }
    }

    public static func deletePairRecord(withID id: String) throws {
        try check(usbmuxd_delete_pair_record(id))
    }

    public static func setUseInotify(_ useInotify: Bool) {
        libusbmuxd_set_use_inotify(useInotify ? 1 : 0)
    }

    public static func setDebugLevel(_ debugLevel: Int) {
        libusbmuxd_set_debug_level(.init(debugLevel))
    }

}
