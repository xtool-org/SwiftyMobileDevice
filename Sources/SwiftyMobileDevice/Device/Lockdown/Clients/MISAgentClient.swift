//
//  MISAgentClient.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 21/03/21.
//  Copyright © 2021 Kabir Oberai. All rights reserved.
//

import Foundation
import libimobiledevice
import plist

public final class MISAgentClient: LockdownService {

    public enum Error: CAPIError, LocalizedError {
        case unknown
        case invalidArg
        case plistError
        case connFailed
        case requestFailed

        public init?(_ raw: misagent_error_t) {
            switch raw {
            case MISAGENT_E_SUCCESS:
                return nil
            case MISAGENT_E_INVALID_ARG:
                self = .invalidArg
            case MISAGENT_E_PLIST_ERROR:
                self = .plistError
            case MISAGENT_E_CONN_FAILED:
                self = .connFailed
            case MISAGENT_E_REQUEST_FAILED:
                self = .requestFailed
            default:
                self = .unknown
            }
        }

        public var errorDescription: String? {
            "MISAgentClient.Error.\(self)"
        }
    }

    public typealias Raw = misagent_client_t
    public static let serviceIdentifier = MISAGENT_SERVICE_NAME
    public static nonisolated(unsafe) let newFunc: NewFunc = misagent_client_new
    public static nonisolated(unsafe) let startFunc: StartFunc = misagent_client_start_service
    public nonisolated(unsafe) let raw: misagent_client_t
    public required init(raw: misagent_client_t) { self.raw = raw }
    deinit { misagent_client_free(raw) }

    private let encoder = PlistNodeEncoder()
    private let decoder = PlistNodeDecoder()

    public var statusCode: Int32 { misagent_get_status_code(raw) }

    public func install(profile: Data) throws {
        try encoder.withEncoded(profile) {
            try CAPI<Error>.check(misagent_install(raw, $0))
        }
    }

    // iOS < 9.3
    public func profilesLegacy() throws -> [Data] {
        try decoder.decode([Data].self) { try CAPI<Error>.check(misagent_copy(raw, &$0)) }
    }

    // iOS >= 9.3
    public func profiles() throws -> [Data] {
        try decoder.decode([Data].self) { try CAPI<Error>.check(misagent_copy_all(raw, &$0)) }
    }

    public func removeProfile(withUUID uuid: String) throws {
        try CAPI<Error>.check(misagent_remove(raw, uuid))
    }

}
