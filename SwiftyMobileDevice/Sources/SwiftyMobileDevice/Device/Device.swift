//
//  Device.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 13/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation
import libimobiledevice

extension ConnectionType {
    public var ideviceRaw: idevice_connection_type {
        switch self {
        case .usb: return CONNECTION_USBMUXD
        case .network: return CONNECTION_NETWORK
        }
    }

    public init?(ideviceRaw: idevice_connection_type) {
        switch ideviceRaw {
        case CONNECTION_USBMUXD: self = .usb
        case CONNECTION_NETWORK: self = .network
        default: return nil
        }
    }
}

extension LookupMode {
    public var ideviceRaw: idevice_options {
        switch self {
        case .only(.usb): return IDEVICE_LOOKUP_USBMUX
        case .only(.network): return IDEVICE_LOOKUP_NETWORK
        case .both(preferring: .usb):
            return .init(
                IDEVICE_LOOKUP_USBMUX.rawValue |
                    IDEVICE_LOOKUP_NETWORK.rawValue
            )
        case .both(preferring: .network):
            return .init(
                IDEVICE_LOOKUP_USBMUX.rawValue |
                    IDEVICE_LOOKUP_NETWORK.rawValue |
                    IDEVICE_LOOKUP_PREFER_NETWORK.rawValue
            )
        }
    }
}

public class Device {

    public enum Error: CAPIError {
        case unknown
        case `internal`
        case invalidArg
        case noDevice
        case notEnoughData
        case sslError
        case timeout

        public init?(_ raw: idevice_error_t) {
            switch raw {
            case IDEVICE_E_SUCCESS: return nil
            case IDEVICE_E_INVALID_ARG: self = .invalidArg
            case IDEVICE_E_NO_DEVICE: self = .noDevice
            case IDEVICE_E_NOT_ENOUGH_DATA: self = .notEnoughData
            case IDEVICE_E_SSL_ERROR: self = .sslError
            case IDEVICE_E_TIMEOUT: self = .timeout
            case IDEVICE_E_UNKNOWN_ERROR: self = .unknown
            default: self = .unknown
            }
        }
    }

    public enum DebugLevel: Int {
        case off = 0
        case on = 1
    }

    public static func setDebugLevel(_ level: DebugLevel) {
        idevice_set_debug_level(.init(level.rawValue))
    }

    public let raw: idevice_t
    public init(udid: String, lookupMode: LookupMode = .only(.usb)) throws {
        var device: idevice_t?
        try CAPI<Error>.check(idevice_new_with_options(&device, udid, lookupMode.ideviceRaw))
        guard let raw = device else { throw Error.internal }
        self.raw = raw
    }
    deinit { idevice_free(raw) }

    public func udid() throws -> String {
        try CAPI<Error>.getString { idevice_get_udid(raw, &$0) }
    }

    public func handle() throws -> UInt32 {
        var handle: UInt32 = 0
        try CAPI<Error>.check(idevice_get_handle(raw, &handle))
        return handle
    }

}
