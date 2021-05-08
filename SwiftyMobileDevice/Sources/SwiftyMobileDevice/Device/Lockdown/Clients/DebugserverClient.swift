//
//  DebugserverClient.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 21/03/21.
//  Copyright © 2021 Kabir Oberai. All rights reserved.
//

import Foundation
import libimobiledevice

public class DebugserverClient: LockdownService {

    public enum Error: CAPIError, LocalizedError {
        case unknown
        case `internal`
        case invalidArg
        case muxError
        case sslError
        case responseError
        case timeout

        public init?(_ raw: debugserver_error_t) {
            switch raw {
            case DEBUGSERVER_E_SUCCESS:
                return nil
            case DEBUGSERVER_E_INVALID_ARG:
                self = .invalidArg
            case DEBUGSERVER_E_MUX_ERROR:
                self = .muxError
            case DEBUGSERVER_E_SSL_ERROR:
                self = .sslError
            case DEBUGSERVER_E_RESPONSE_ERROR:
                self = .responseError
            case DEBUGSERVER_E_TIMEOUT:
                self = .timeout
            default:
                self = .unknown
            }
        }

        public var errorDescription: String? {
            "DebugserverClient.Error.\(self)"
        }
    }

    public typealias Raw = debugserver_client_t
    public static let serviceIdentifier = DEBUGSERVER_SERVICE_NAME // not used
    public static let newFunc: NewFunc = debugserver_client_new
    public static let startFunc: StartFunc = debugserver_client_start_service
    public let raw: debugserver_client_t
    public required init(raw: debugserver_client_t) { self.raw = raw }
    public static func startService(
        withFunc fn: (String) throws -> lockdownd_service_descriptor_t
    ) throws -> lockdownd_service_descriptor_t {
        // try secure version first
        try (try? fn("com.apple.debugserver.DVTSecureSocketProxy"))
            ?? fn(DEBUGSERVER_SERVICE_NAME)
    }
    deinit { debugserver_client_free(raw) }

    @discardableResult
    public func send(command commandName: String, arguments: [String]) throws -> Data {
        var cArgs: [UnsafeMutablePointer<Int8>?] = arguments.map { strdup($0) }
        defer { cArgs.forEach { free($0) } }
        var rawCommand: debugserver_command_t?
        try CAPI<Error>.check(debugserver_command_new(commandName, Int32(cArgs.count), &cArgs, &rawCommand))
        guard let command = rawCommand else { throw Error.internal }
        defer { debugserver_command_free(command) }
        return try CAPI<Error>.getData { resp, rawSize in
            var size: Int {
                get { Int(rawSize) }
                set { rawSize = .init(newValue) }
            }
            return debugserver_client_send_command(raw, command, &resp, &size)
        }
    }

    public func setACKEnabled(_ enabled: Bool) throws {
        try CAPI<Error>.check(debugserver_client_set_ack_mode(raw, enabled ? 1 : 0))
    }

    public func setEnvironment(key: String, value: String) throws -> String {
        try CAPI<Error>.getString {
            debugserver_client_set_environment_hex_encoded(raw, "\(key)=\(value)", &$0)
        }
    }

    public func launch(executable: URL, arguments: [String]) throws -> String {
        var rawArgs = [executable.withUnsafeFileSystemRepresentation { strdup($0!) }]
            + arguments.map { strdup($0) }
        defer { rawArgs.forEach { free($0) } }
        return try CAPI<Error>.getString {
            debugserver_client_set_argv(raw, Int32(rawArgs.count), &rawArgs, &$0)
        }
    }

    public static func hexEncode(_ string: String) throws -> Data {
        try CAPI<CAPINoError>.getData { debugserver_encode_string(string, &$0, &$1) }
    }

    public static func hexDecode(_ data: Data) throws -> String {
        try data.withUnsafeBytes { buf in
            let bound = buf.bindMemory(to: Int8.self)
            return try CAPI<CAPINoError>.getString {
                debugserver_decode_string(bound.baseAddress!, bound.count, &$0)
            }
        }
    }

}
