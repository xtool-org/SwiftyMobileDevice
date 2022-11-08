//
//  LockdownClient.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 13/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation
import Superutils
import libimobiledevice

public class LockdownClient {

    public enum Error: CAPIError, LocalizedError {
        case unknown
        case `internal`
        case invalidArg
        case invalidConf
        case plistError
        case pairingFailed
        case sslError
        case dictError
        case receiveTimeout
        case muxError
        case noRunningSession
        case invalidResponse
        case missingKey
        case missingValue
        case getProhibited
        case setProhibited
        case removeProhibited
        case immutableValue
        case passwordProtected
        case userDeniedPairing
        case pairingDialogResponsePending
        case missingHostID
        case invalidHostID
        case sessionActive
        case sessionInactive
        case missingSessionID
        case invalidSessionID
        case missingService
        case invalidService
        case serviceLimit
        case missingPairRecord
        case savePairRecordFailed
        case invalidPairRecord
        case invalidActivationRecord
        case missingActivationRecord
        case serviceProhibited
        case escrowLocked
        case pairingProhibitedOverThisConnection
        case fmipProtected
        case mcProtected
        case mcChallengeRequired

        // swiftlint:disable:next cyclomatic_complexity
        public init?(_ raw: lockdownd_error_t) {
            switch raw {
            case LOCKDOWN_E_SUCCESS:
                return nil
            case LOCKDOWN_E_INVALID_ARG:
                self = .invalidArg
            case LOCKDOWN_E_INVALID_CONF:
                self = .invalidConf
            case LOCKDOWN_E_PLIST_ERROR:
                self = .plistError
            case LOCKDOWN_E_PAIRING_FAILED:
                self = .pairingFailed
            case LOCKDOWN_E_SSL_ERROR:
                self = .sslError
            case LOCKDOWN_E_DICT_ERROR:
                self = .dictError
            case LOCKDOWN_E_RECEIVE_TIMEOUT:
                self = .receiveTimeout
            case LOCKDOWN_E_MUX_ERROR:
                self = .muxError
            case LOCKDOWN_E_NO_RUNNING_SESSION:
                self = .noRunningSession
            case LOCKDOWN_E_INVALID_RESPONSE:
                self = .invalidResponse
            case LOCKDOWN_E_MISSING_KEY:
                self = .missingKey
            case LOCKDOWN_E_MISSING_VALUE:
                self = .missingValue
            case LOCKDOWN_E_GET_PROHIBITED:
                self = .getProhibited
            case LOCKDOWN_E_SET_PROHIBITED:
                self = .setProhibited
            case LOCKDOWN_E_REMOVE_PROHIBITED:
                self = .removeProhibited
            case LOCKDOWN_E_IMMUTABLE_VALUE:
                self = .immutableValue
            case LOCKDOWN_E_PASSWORD_PROTECTED:
                self = .passwordProtected
            case LOCKDOWN_E_USER_DENIED_PAIRING:
                self = .userDeniedPairing
            case LOCKDOWN_E_PAIRING_DIALOG_RESPONSE_PENDING:
                self = .pairingDialogResponsePending
            case LOCKDOWN_E_MISSING_HOST_ID:
                self = .missingHostID
            case LOCKDOWN_E_INVALID_HOST_ID:
                self = .invalidHostID
            case LOCKDOWN_E_SESSION_ACTIVE:
                self = .sessionActive
            case LOCKDOWN_E_SESSION_INACTIVE:
                self = .sessionInactive
            case LOCKDOWN_E_MISSING_SESSION_ID:
                self = .missingSessionID
            case LOCKDOWN_E_INVALID_SESSION_ID:
                self = .invalidSessionID
            case LOCKDOWN_E_MISSING_SERVICE:
                self = .missingService
            case LOCKDOWN_E_INVALID_SERVICE:
                self = .invalidService
            case LOCKDOWN_E_SERVICE_LIMIT:
                self = .serviceLimit
            case LOCKDOWN_E_MISSING_PAIR_RECORD:
                self = .missingPairRecord
            case LOCKDOWN_E_SAVE_PAIR_RECORD_FAILED:
                self = .savePairRecordFailed
            case LOCKDOWN_E_INVALID_PAIR_RECORD:
                self = .invalidPairRecord
            case LOCKDOWN_E_INVALID_ACTIVATION_RECORD:
                self = .invalidActivationRecord
            case LOCKDOWN_E_MISSING_ACTIVATION_RECORD:
                self = .missingActivationRecord
            case LOCKDOWN_E_SERVICE_PROHIBITED:
                self = .serviceProhibited
            case LOCKDOWN_E_ESCROW_LOCKED:
                self = .escrowLocked
            case LOCKDOWN_E_PAIRING_PROHIBITED_OVER_THIS_CONNECTION:
                self = .pairingProhibitedOverThisConnection
            case LOCKDOWN_E_FMIP_PROTECTED:
                self = .fmipProtected
            case LOCKDOWN_E_MC_PROTECTED:
                self = .mcProtected
            case LOCKDOWN_E_MC_CHALLENGE_REQUIRED:
                self = .mcChallengeRequired
            default:
                self = .unknown
            }
        }

        public var errorDescription: String? {
            "LockdownClient.Error.\(self)"
        }
    }

    public final class ServiceDescriptor {
        public let port: UInt16
        public let isSSLEnabled: Bool
        public let identifier: String

        public let raw: lockdownd_service_descriptor_t
        public init(raw: lockdownd_service_descriptor_t) {
            self.raw = raw
            self.port = raw.pointee.port
            self.isSSLEnabled = raw.pointee.ssl_enabled != 0
            self.identifier = String(cString: raw.pointee.identifier)
        }

        public convenience init<T: LockdownService>(
            client: LockdownClient, type: T.Type = T.self, sendEscrowBag: Bool = false
        ) throws {
            let raw = try T.startService { id in
                var descriptor: lockdownd_service_descriptor_t?
                try CAPI<Error>.check(
                    (sendEscrowBag ? lockdownd_start_service_with_escrow_bag : lockdownd_start_service)(
                        client.raw, id, &descriptor
                    )
                )
                return try descriptor.orThrow(Error.internal)
            }
            self.init(raw: raw)
        }

        deinit { lockdownd_service_descriptor_free(raw) }
    }

    public struct SessionID: RawRepresentable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }

    public struct PairRecord {
        // these certificates must be PEM-encoded
        public let deviceCertificate: Data
        public let hostCertificate: Data
        public let rootCertificate: Data

        public let hostID: String
        public let systemBUID: String

        public init?(
            deviceCertificate: Data,
            hostCertificate: Data,
            rootCertificate: Data,
            hostID: String,
            systemBUID: String
        ) {
            func nullTerminating(_ data: Data) -> Data {
                if data.last == 0 { return data }
                var copy = data
                copy.append(0)
                return copy
            }

            self.deviceCertificate = nullTerminating(deviceCertificate)
            self.hostCertificate = nullTerminating(hostCertificate)
            self.rootCertificate = nullTerminating(rootCertificate)
            self.hostID = hostID
            self.systemBUID = systemBUID
        }

        // the members of `raw` are copied
        public init(raw: lockdownd_pair_record) {
            // data from null terminated bytes
            func data(from bytes: UnsafePointer<Int8>) -> Data {
                Data(bytes: bytes, count: strlen(bytes) + 1) // include NUL byte
            }
            deviceCertificate = data(from: raw.device_certificate)
            hostCertificate = data(from: raw.host_certificate)
            rootCertificate = data(from: raw.root_certificate)
            hostID = String(cString: raw.host_id)
            systemBUID = String(cString: raw.system_buid)
        }

        public init(raw: lockdownd_pair_record_t) {
            self.init(raw: raw.pointee)
        }

        public func withRaw<Result>(_ block: (lockdownd_pair_record_t) throws -> Result) rethrows -> Result {
            try deviceCertificate.withUnsafeBytes { buf in
                let boundDeviceCertificate = UnsafeMutableBufferPointer(mutating: buf.bindMemory(to: Int8.self))
                return try hostCertificate.withUnsafeBytes { buf in
                    let boundHostCertificate = UnsafeMutableBufferPointer(mutating: buf.bindMemory(to: Int8.self))
                    return try rootCertificate.withUnsafeBytes { buf in
                        let boundRootCertificate = UnsafeMutableBufferPointer(mutating: buf.bindMemory(to: Int8.self))
                        return try hostID.withCString { cHostID in
                            let mutableHostID = UnsafeMutablePointer(mutating: cHostID)
                            return try systemBUID.withCString { cSystemBUID in
                                let mutableSystemBUID = UnsafeMutablePointer(mutating: cSystemBUID)
                                // the base addresses are known to be non-nil because the data values are
                                // null terminated so they have to have at least one byte (the NUL character)
                                var record = lockdownd_pair_record(
                                    device_certificate: boundDeviceCertificate.baseAddress!,
                                    host_certificate: boundHostCertificate.baseAddress!,
                                    root_certificate: boundRootCertificate.baseAddress!,
                                    host_id: mutableHostID,
                                    system_buid: mutableSystemBUID
                                )
                                return try withUnsafeMutablePointer(to: &record) { ptr in
                                    try block(ptr)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private let encoder = PlistNodeEncoder()
    private let decoder = PlistNodeDecoder()

    public let raw: lockdownd_client_t
    public init(raw: lockdownd_client_t) { self.raw = raw }
    public init(device: Device, label: String?, performHandshake: Bool) throws {
        var client: lockdownd_client_t?
        try CAPI<Error>.check(
            (performHandshake ? lockdownd_client_new_with_handshake : lockdownd_client_new)(
                device.raw, &client, label
            )
        )
        guard let raw = client else { throw Error.internal }
        self.raw = raw
    }
    deinit { lockdownd_client_free(raw) }

    public func setLabel(_ label: String?) {
        lockdownd_client_set_label(raw, label)
    }

    public func deviceUDID() throws -> String {
        try CAPI<Error>.getString { lockdownd_get_device_udid(raw, &$0) }
    }

    public func deviceName() throws -> String {
        try CAPI<Error>.getString { lockdownd_get_device_name(raw, &$0) }
    }

    public func queryType() throws -> String {
        try CAPI<Error>.getString { lockdownd_query_type(raw, &$0) }
    }

    public func syncDataClasses() throws -> [String] {
        try CAPI<Error>.getArrayWithCount(
            parseFn: { lockdownd_get_sync_data_classes(raw, &$0, &$1) },
            freeFn: { lockdownd_data_classes_free($0) }
        ) ?? []
    }

    public func value<T: Decodable>(ofType type: T.Type, forDomain domain: String?, key: String?) throws -> T {
        try decoder.decode(type) {
            try CAPI<Error>.check(lockdownd_get_value(raw, domain, key, &$0))
        }
    }

    public func setValue<T: Encodable>(_ value: T?, forDomain domain: String, key: String) throws {
        if let value = value {
            // this follows move semantics, so we aren't responsible for freeing the created plist_t
            try CAPI<Error>.check(lockdownd_set_value(raw, domain, key, encoder.encode(value)))
        } else {
            try CAPI<Error>.check(lockdownd_remove_value(raw, domain, key))
        }
    }

    public func startService<T: LockdownService>(
        ofType type: T.Type = T.self,
        sendEscrowBag: Bool = false
    ) throws -> ServiceDescriptor {
        try ServiceDescriptor(client: self, type: T.self, sendEscrowBag: sendEscrowBag)
    }

    public func startSession(
        withHostID hostID: String
    ) throws -> (sessionID: SessionID, isSSLEnabled: Bool) {
        var isSSLEnabled: Int32 = 0
        let sessionID = try CAPI<Error>.getString {
            lockdownd_start_session(raw, hostID, &$0, &isSSLEnabled)
        }
        return (.init(rawValue: sessionID), isSSLEnabled != 0)
    }

    public func stopSession(_ sessionID: SessionID) throws {
        try CAPI<Error>.check(lockdownd_stop_session(raw, sessionID.rawValue))
    }

    public func send<T: Encodable>(_ value: T) throws {
        try CAPI<Error>.check(encoder.withEncoded(value) {
            lockdownd_send(raw, $0)
        })
    }

    public func receive<T: Decodable>(_ type: T.Type) throws -> T {
        try decoder.decode(type) {
            try CAPI<Error>.check(lockdownd_receive(raw, &$0))
        }
    }

    private func withRawRecord<Result>(
        _ record: PairRecord?,
        _ block: (lockdownd_pair_record_t?) throws -> Result
    ) rethrows -> Result {
        if let record = record {
            return try record.withRaw { try block($0) }
        } else {
            return try block(nil)
        }
    }

    public func pair(
        withRecord record: PairRecord? = nil,
        options: [String: Encodable] = ["ExtendedPairingErrors": true]
    ) throws {
        try CAPI<Error>.check(encoder.withEncoded(options.mapValues(AnyEncodable.init)) { encodedOptions in
            withRawRecord(record) { lockdownd_pair_with_options(raw, $0, encodedOptions, nil) }
        })
    }

    public func pair<D: Decodable>(
        returnType: D.Type,
        record: PairRecord? = nil,
        options: [String: Encodable] = ["ExtendedPairingErrors": true]
    ) throws -> D {
        try decoder.decode(returnType) { buf in
            try CAPI<Error>.check(encoder.withEncoded(options.mapValues(AnyEncodable.init)) { encodedOptions in
                withRawRecord(record) { lockdownd_pair_with_options(raw, $0, encodedOptions, &buf) }
            })
        }
    }

    private func validateRecord(_ record: PairRecord?) throws {
        try CAPI<Error>.check(withRawRecord(record) { lockdownd_validate_pair(raw, $0) })
    }

    public func validate(record: PairRecord) throws {
        try validateRecord(record)
    }

    public func validateInternalRecord() throws {
        try validateRecord(nil)
    }

    public func unpair(withRecord record: PairRecord? = nil) throws {
        try CAPI<Error>.check(withRawRecord(record) { lockdownd_unpair(raw, $0) })
    }

    public func activate(withActivationRecord record: [String: Encodable]) throws {
        try CAPI<Error>.check(encoder.withEncoded(record.mapValues(AnyEncodable.init)) {
            lockdownd_activate(raw, $0)
        })
    }

    public func deactivate() throws {
        try CAPI<Error>.check(lockdownd_deactivate(raw))
    }

    public func enterRecovery() throws {
        try CAPI<Error>.check(lockdownd_enter_recovery(raw))
    }

    public func sendGoodbye() throws {
        try CAPI<Error>.check(lockdownd_goodbye(raw))
    }

}
