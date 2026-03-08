import Foundation
import libimobiledevice

public final class PropertyListClient {
    public enum Error: CAPIError {
        case unknown
        case invalidArg
        case plistError
        case muxError
        case sslError
        case receiveTimeout
        case notEnoughData

        public init?(_ raw: property_list_service_error_t) {
            switch raw {
            case PROPERTY_LIST_SERVICE_E_SUCCESS:
                return nil
            case PROPERTY_LIST_SERVICE_E_INVALID_ARG:
                self = .invalidArg
            case PROPERTY_LIST_SERVICE_E_PLIST_ERROR:
                self = .plistError
            case PROPERTY_LIST_SERVICE_E_MUX_ERROR:
                self = .muxError
            case PROPERTY_LIST_SERVICE_E_SSL_ERROR:
                self = .sslError
            case PROPERTY_LIST_SERVICE_E_RECEIVE_TIMEOUT:
                self = .receiveTimeout
            case PROPERTY_LIST_SERVICE_E_NOT_ENOUGH_DATA:
                self = .notEnoughData
            case PROPERTY_LIST_SERVICE_E_UNKNOWN_ERROR:
                self = .unknown
            default:
                self = .unknown
            }
        }
    }

    public enum Format: Sendable {
        case xml
        case binary
    }

    public let raw: property_list_service_client_t
    private let encoder = PlistNodeEncoder()
    private let decoder = PlistNodeDecoder()

    public init(
        device: Device,
        lockdownClient: LockdownClient,
        serviceIdentifier: String,
        sendEscrowBag: Bool = false,
    ) throws {
        let descriptor = try lockdownClient.startService(
            identifier: serviceIdentifier,
            sendEscrowBag: sendEscrowBag
        )
        var client: property_list_service_client_t?
        let status = property_list_service_client_new(device.raw, descriptor.raw, &client)
        try CAPI<Error>.check(status)
        guard let client else { throw Error.unknown }
        self.raw = client
    }

    deinit {
        property_list_service_client_free(raw)
    }

    public func send<T: Encodable>(
        _ value: T,
        format: Format
    ) throws {
        let status = try encoder.withEncoded(value) {
            switch format {
            case .xml: property_list_service_send_xml_plist(raw, $0)
            case .binary: property_list_service_send_binary_plist(raw, $0)
            }
        }
        try CAPI<Error>.check(status)
    }

    public func receive<D: Decodable>(type _: D.Type = D.self) throws -> D {
        try decoder.decode(D.self) {
            try CAPI<Error>.check(property_list_service_receive_plist(raw, &$0))
        }
    }
}
