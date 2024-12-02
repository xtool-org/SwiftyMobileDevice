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

    public struct Event: Sendable {
        public enum EventType: Sendable {
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

    public static func subscribe() async -> AsyncStream<Device.Event> {
        await SubscriptionManager.shared.subscribe()
    }

}

private actor SubscriptionManager {
    static let shared = SubscriptionManager()

    private var subscriptionContext: idevice_subscription_context_t?
    private var subscribers: [ObjectIdentifier: @Sendable (Device.Event) -> Void] = [:]

    private func yield(event: Device.Event) {
        for (_, subscriber) in subscribers {
            subscriber(event)
        }
    }

    private final class SubscriptionToken: Sendable {
        fileprivate init() {}
    }

    private func actuallySubscribe() {
        var context: idevice_subscription_context_t?
        idevice_events_subscribe(&context, { @Sendable eventPointer, _ in
            guard let rawEvent = eventPointer?.pointee,
                  let event = Device.Event(raw: rawEvent)
                  else { return }
            Task {
                await SubscriptionManager.shared.yield(event: event)
            }
        }, nil)
        self.subscriptionContext = context
    }

    public func subscribe() -> AsyncStream<Device.Event> {
        if subscriptionContext == nil {
            actuallySubscribe()
        }
        let token = SubscriptionToken()
        let (stream, continuation) = AsyncStream<Device.Event>.makeStream()
        subscribers[ObjectIdentifier(token)] = { continuation.yield($0) }
        continuation.onTermination = { _ in
            Task { await self.unsubscribe(token: token) }
        }
        return stream
    }

    private func unsubscribe(token: SubscriptionToken) {
        subscribers.removeValue(forKey: ObjectIdentifier(token))
        if subscribers.isEmpty, let subscriptionContext {
            idevice_events_unsubscribe(subscriptionContext)
            self.subscriptionContext = nil
        }
    }

}
