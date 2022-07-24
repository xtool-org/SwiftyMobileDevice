//
//  Device+Lookup.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 28/04/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

import Foundation
import libimobiledevice

extension Device {

    public struct Info {
        public let udid: String
        public let connectionType: ConnectionType

        // copies from raw
        init?(raw: idevice_info) {
            guard let connectionType = ConnectionType(ideviceRaw: raw.conn_type)
                else { return nil }
            self.udid = String(cString: raw.udid)
            self.connectionType = connectionType
        }
    }

    public struct Event {
        public enum EventType {
            case add
            case remove
            case paired

            public var raw: idevice_event_type {
                switch self {
                case .add: return IDEVICE_DEVICE_ADD
                case .remove: return IDEVICE_DEVICE_REMOVE
                case .paired: return IDEVICE_DEVICE_PAIRED
                }
            }

            public init?(_ raw: idevice_event_type) {
                switch raw {
                case IDEVICE_DEVICE_ADD: self = .add
                case IDEVICE_DEVICE_REMOVE: self = .remove
                case IDEVICE_DEVICE_PAIRED: self = .paired
                default: return nil
                }
            }
        }

        public let eventType: EventType
        public let udid: String
        public let connectionType: ConnectionType

        public init?(raw: idevice_event_t) {
            guard let eventType = EventType(raw.event),
                  let connectionType = ConnectionType(ideviceRaw: raw.conn_type)
                else { return nil }
            self.eventType = eventType
            // we don't own `raw` so we need to copy the udid string
            self.udid = String(cString: raw.udid)
            self.connectionType = connectionType
        }
    }

    public class SubscriptionToken {
        fileprivate init() {}
    }

    private class Subscription {
        private weak var token: SubscriptionToken?
        private let callback: (Event) -> Void

        init(token: SubscriptionToken, callback: @escaping (Event) -> Void) {
            self.token = token
            self.callback = callback
        }

        /// - Returns: whether `token` is alive
        func notify(withEvent event: Event) -> Bool {
            guard token != nil else { return false }
            callback(event)
            return true
        }
    }

    @available(*, deprecated, renamed: "devices")
    public static func udids() throws -> [String] {
        try CAPI<Error>.getArrayWithCount(
            parseFn: { idevice_get_device_list(&$0, &$1) },
            freeFn: { idevice_device_list_free($0) }
        ) ?? []
    }

    public static func devices() throws -> [Info] {
        var deviceList: UnsafeMutablePointer<idevice_info_t?>?
        var count: Int32 = 0
        try CAPI<Error>.check(idevice_get_device_list_extended(&deviceList, &count))

        guard let devices = deviceList else { throw CAPIGenericError.unexpectedNil }
        defer { idevice_device_list_extended_free(deviceList) }

        return UnsafeBufferPointer(start: devices, count: Int(count))
            .compactMap { $0?.pointee }
            .compactMap(Info.init)
    }

    private static var subscriptionLock = NSLock()
    private static var subscribers: [ObjectIdentifier: Subscription] = [:]
    private static var isSubscribed = false

    private static func actuallySubscribeIfNeeded() {
        guard !isSubscribed else { return }
        isSubscribed = true
        idevice_event_subscribe({ eventPointer, _ in
            guard let rawEvent = eventPointer?.pointee,
                let event = Event(raw: rawEvent)
                else { return }
            // notify subscribers and remove the ones where token has been deallocated
            Device.subscribers.filter { _, subscription in
                !subscription.notify(withEvent: event)
            }.forEach { key, _ in
                Device.subscribers.removeValue(forKey: key)
            }
        }, nil)
    }

    public static func subscribe(callback: @escaping (Event) -> Void) -> SubscriptionToken {
        subscriptionLock.lock()
        defer { subscriptionLock.unlock() }
        actuallySubscribeIfNeeded()
        let token = SubscriptionToken()
        subscribers[ObjectIdentifier(token)] = Subscription(token: token, callback: callback)
        return token
    }

    public static func unsubscribe(token: SubscriptionToken) {
        subscriptionLock.lock()
        defer { subscriptionLock.unlock() }

        subscribers.removeValue(forKey: ObjectIdentifier(token))

        if subscribers.isEmpty {
            idevice_event_unsubscribe()
            isSubscribed = false
        }
    }

}
