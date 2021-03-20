//
//  USBMux+Lookup.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 11/04/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

import Foundation
import usbmuxd

extension USBMux {

    public enum LookupMode {
        case only(ConnectionType)
        case both(preferring: ConnectionType)

        public var raw: usbmux_lookup_options {
            switch self {
            case .only(.usb): return DEVICE_LOOKUP_USBMUX
            case .only(.network): return DEVICE_LOOKUP_NETWORK
            case .both(preferring: .usb):
                return .init(
                    DEVICE_LOOKUP_USBMUX.rawValue |
                        DEVICE_LOOKUP_NETWORK.rawValue
                )
            case .both(preferring: .network):
                return .init(
                    DEVICE_LOOKUP_USBMUX.rawValue |
                        DEVICE_LOOKUP_NETWORK.rawValue |
                        DEVICE_LOOKUP_PREFER_NETWORK.rawValue
                )
            }
        }
    }

    public struct Event {
        public enum Kind {
            case added
            case removed
            case paired

            var raw: usbmuxd_event_type {
                switch self {
                case .added: return UE_DEVICE_ADD
                case .removed: return UE_DEVICE_REMOVE
                case .paired: return UE_DEVICE_PAIRED
                }
            }

            init?(raw: usbmuxd_event_type) {
                switch raw {
                case UE_DEVICE_ADD: self = .added
                case UE_DEVICE_REMOVE: self = .removed
                case UE_DEVICE_PAIRED: self = .paired
                default: return nil
                }
            }
        }

        public let kind: Kind
        public let device: Device

        init?(raw: usbmuxd_event_t) {
            guard let kind = Kind(raw: .init(.init(raw.event))),
                let device = Device(raw: raw.device)
                else { return nil }
            self.kind = kind
            self.device = device
        }
    }

    public class SubscriptionToken {
        fileprivate var userData: SubscriptionUserData
        fileprivate let context: usbmuxd_subscription_context_t
        fileprivate init(userData: SubscriptionUserData, context: usbmuxd_subscription_context_t) {
            self.userData = userData
            self.context = context
        }
    }

    fileprivate class SubscriptionUserData {
        let callback: (Event) -> Void
        init(callback: @escaping (Event) -> Void) {
            self.callback = callback
        }
    }

    // TODO: Do something similar to Device.swift here, with a single global handler instead
    public static func subscribe(withCallback callback: @escaping (Event) -> Void) throws -> SubscriptionToken {
        let userData = SubscriptionUserData(callback: callback)
        let opaqueUserData = Unmanaged.passRetained(userData).toOpaque()

        var context: usbmuxd_subscription_context_t?
        try CAPI<Error>.check(usbmuxd_events_subscribe(&context, { rawEvent, opaqueUserData in
            let userData = Unmanaged<SubscriptionUserData>.fromOpaque(opaqueUserData!).takeUnretainedValue()
            guard let event = Event(raw: rawEvent!.pointee) else { return }
            userData.callback(event)
        }, opaqueUserData))

        return SubscriptionToken(userData: userData, context: context!)
    }

    public static func unsubscribe(withToken token: SubscriptionToken) throws {
        try CAPI<Error>.check(usbmuxd_events_unsubscribe(token.context))
        // balance the initial retain in `subscribe`
        Unmanaged.passUnretained(token.userData).release()
    }

    public static func allDevices() throws -> [Device] {
        var devices: UnsafeMutablePointer<usbmuxd_device_info_t>?
        defer { devices.map { free($0) } }

        let count = usbmuxd_get_device_list(&devices)
        switch count {
        case ..<0:
            throw Error.errno(.init(count))
        case 0:
            return []
        default:
            return UnsafeBufferPointer(start: devices!, count: .init(count)).compactMap(Device.init)
        }
    }

    public static func device(withUDID udid: String, mode: LookupMode? = nil) throws -> Device? {
        var device = usbmuxd_device_info_t()
        let result: Int32
        if let mode = mode {
            result = usbmuxd_get_device(udid, &device, mode.raw)
        } else {
            result = usbmuxd_get_device_by_udid(udid, &device)
        }
        switch result {
        case 1: // found
            return Device(raw: device)
        case 0: // not found
            return nil
        case let error: // error (-ve)
            throw Error.errno(.init(error))
        }
    }

}
