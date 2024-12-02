//
//  USBMux.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 11/04/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

import Foundation
import usbmuxd

extension ConnectionType {
    public var usbmuxRaw: usbmux_connection_type {
        switch self {
        case .usb: return CONNECTION_TYPE_USB
        case .network: return CONNECTION_TYPE_NETWORK
        }
    }

    public init?(usbmuxRaw: usbmux_connection_type) {
        switch usbmuxRaw {
        case CONNECTION_TYPE_USB: self = .usb
        case CONNECTION_TYPE_NETWORK: self = .network
        default: return nil
        }
    }
}

public enum USBMux {

    public enum Error: LocalizedError, CAPIError {
        case errno(Int32)

        public var errorDescription: String? {
            switch self {
            case .errno(let raw):
                // We need to make a copy here. strerror uses a static buffer for
                // unknown errors, which may be overwritten by future calls.
                return String(cString: strerror(raw)!)
            }
        }

        public init?(_ raw: Int32) {
            guard raw != 0 else { return nil }
            self = .errno(raw)
        }
    }

    public struct Device: Sendable {
        public struct Handle: Sendable {
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
            let udidSize = MemoryLayout.size(ofValue: udidRaw)
            self.udid = withUnsafePointer(to: &udidRaw) {
                UnsafeRawPointer($0)
                    // Tuple is also bound to type of elements (if homogeneous) so this is legal
                    .assumingMemoryBound(to: Int8.self)
                    // UInt8 has same size and stride as Int8 so this is okay too
                    .withMemoryRebound(to: UInt8.self, capacity: udidSize, String.init(cString:))
            }

            guard let connectionType = ConnectionType(usbmuxRaw: raw.conn_type) else { return nil }
            self.connectionType = connectionType

            var dataRaw = raw.conn_data
            self.connectionData = Data(bytes: &dataRaw.0, count: MemoryLayout.size(ofValue: dataRaw))
        }
    }

    public static func buid() throws -> String {
        try CAPI<Error>.getString { usbmuxd_read_buid(&$0) }
    }

    public static func pairRecord(forUDID udid: String) throws -> Data {
        try CAPI<Error>.getData { usbmuxd_read_pair_record(udid, &$0, &$1) }
    }

    public static func savePairRecord(_ record: Data, forUDID udid: String, handle: Device.Handle? = nil) throws {
        try record.withUnsafeBytes { buf in
            let bound = buf.bindMemory(to: Int8.self)
            try CAPI<Error>.check(
                usbmuxd_save_pair_record_with_device_id(udid, handle?.raw ?? 0, bound.baseAddress, .init(bound.count))
            )
        }
    }

    public static func deletePairRecord(forUDID udid: String) throws {
        try CAPI<Error>.check(usbmuxd_delete_pair_record(udid))
    }

    public static func setUseInotify(_ useInotify: Bool) {
        libusbmuxd_set_use_inotify(useInotify ? 1 : 0)
    }

    public static func setDebugLevel(_ debugLevel: Int) {
        libusbmuxd_set_debug_level(.init(debugLevel))
    }

}
