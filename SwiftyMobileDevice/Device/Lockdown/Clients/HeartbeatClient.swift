//
//  HeartbeatClient.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 13/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation

public class HeartbeatClient: LockdownService {

    public enum Error: CAPIError {
        case unknown
        case `internal`
        case invalidArg
        case plistError
        case muxError
        case sslError
        case notEnoughData
        case timeout

        public init?(_ raw: heartbeat_error_t) {
            switch raw {
            case HEARTBEAT_E_SUCCESS: return nil
            case HEARTBEAT_E_INVALID_ARG: self = .invalidArg
            case HEARTBEAT_E_PLIST_ERROR: self = .plistError
            case HEARTBEAT_E_MUX_ERROR: self = .muxError
            case HEARTBEAT_E_SSL_ERROR: self = .sslError
            case HEARTBEAT_E_NOT_ENOUGH_DATA: self = .notEnoughData
            case HEARTBEAT_E_TIMEOUT: self = .timeout
            default: self = .unknown
            }
        }
    }

    public typealias Raw = heartbeat_client_t
    public static let serviceIdentifier = HEARTBEAT_SERVICE_NAME
    public static let newFunc: NewFunc = heartbeat_client_new
    public static let startFunc: StartFunc = heartbeat_client_start_service
    public let raw: heartbeat_client_t
    public required init(raw: heartbeat_client_t) { self.raw = raw }
    deinit { heartbeat_client_free(raw) }

    private let encoder = PlistNodeEncoder()
    private let decoder = PlistNodeDecoder()

    public func send<T: Encodable>(_ value: T) throws {
        try CAPI<Error>.check(encoder.withEncoded(value) { heartbeat_send(raw, $0) })
    }

    public func receive<T: Decodable>(_ type: T.Type, timeout: TimeInterval? = nil) throws -> T {
        try decoder.decode(type) { buf in
            try CAPI<Error>.check(
                timeout.map {
                    heartbeat_receive_with_timeout(raw, &buf, .init($0 * 1000))
                } ?? heartbeat_receive(raw, &buf)
            )
        }
    }

}
