//
//  HouseArrestClient.swift
//  
//
//  Created by Kabir Oberai on 10/05/21.
//

import Foundation
import libimobiledevice

public final class HouseArrestClient: LockdownService {

    public enum Error: CAPIError, LocalizedError {
        case unknown
        case invalidArg
        case plistError
        case connFailed
        case invalidMode

        public init?(_ raw: house_arrest_error_t) {
            switch raw {
            case HOUSE_ARREST_E_SUCCESS:
                return nil
            case HOUSE_ARREST_E_INVALID_ARG:
                self = .invalidArg
            case HOUSE_ARREST_E_PLIST_ERROR:
                self = .plistError
            case HOUSE_ARREST_E_CONN_FAILED:
                self = .connFailed
            case HOUSE_ARREST_E_INVALID_MODE:
                self = .invalidMode
            default:
                self = .unknown
            }
        }

        public var errorDescription: String? {
            "HouseArrestClient.Error.\(self)"
        }
    }

    public struct RequestFailure: LocalizedError {
        public let reason: String?
        public var errorDescription: String? { reason }
    }

    public enum Vendable {
        case container
        case documents

        var command: String {
            switch self {
            case .container:
                return "VendContainer"
            case .documents:
                return "VendDocuments"
            }
        }
    }

    public typealias Raw = house_arrest_client_t
    public static let serviceIdentifier = HOUSE_ARREST_SERVICE_NAME
    public static let newFunc: NewFunc = house_arrest_client_new
    public static let startFunc: StartFunc = house_arrest_client_start_service
    public let raw: house_arrest_client_t
    public required init(raw: house_arrest_client_t) { self.raw = raw }
    deinit { house_arrest_client_free(raw) }

    private static let decoder = PlistNodeDecoder()

    private struct Result: Decodable {
        enum Status: String, Decodable {
            case complete = "Complete"
        }
        let status: Status?
        let error: String?

        private enum CodingKeys: String, CodingKey {
            case status = "Status"
            case error = "Error"
        }
    }

    private final class AFCChildClient: AFCClient {
        // we need to keep the house_arrest_client_t alive because freeing
        // it closes the AFC connection as well
        private var parent: HouseArrestClient?

        init(parent: HouseArrestClient) throws {
            self.parent = parent

            var raw: afc_client_t?
            try CAPI<Error>.check(afc_client_new_from_house_arrest_client(parent.raw, &raw))

            guard let raw = raw else { throw CAPIGenericError.unexpectedNil }

            super.init(raw: raw)
        }

        required init(raw: afc_client_t) {
            super.init(raw: raw)
        }
    }

    public func vend(_ vendable: Vendable, forApp appID: String) throws -> AFCClient {
        try CAPI<Error>.check(house_arrest_send_command(raw, vendable.command, appID))
        let result = try Self.decoder.decode(Result.self) {
            try CAPI<Error>.check(house_arrest_get_result(raw, &$0))
        }
        guard result.status == .complete else {
            throw RequestFailure(reason: result.error)
        }
        return try AFCChildClient(parent: self)
    }

}
