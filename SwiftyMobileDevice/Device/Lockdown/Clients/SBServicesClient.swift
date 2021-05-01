//
//  SBServicesClient.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 29/03/21.
//  Copyright © 2021 Kabir Oberai. All rights reserved.
//

import Foundation
import libimobiledevice
import plist

public final class SBServicesClient: LockdownService {

    public enum Error: CAPIError, LocalizedError {
        case unknown
        case invalidArg
        case plistError
        case connFailed

        public init?(_ raw: sbservices_error_t) {
            switch raw {
            case SBSERVICES_E_SUCCESS:
                return nil
            case SBSERVICES_E_INVALID_ARG:
                self = .invalidArg
            case SBSERVICES_E_PLIST_ERROR:
                self = .plistError
            case SBSERVICES_E_CONN_FAILED:
                self = .connFailed
            default:
                self = .unknown
            }
        }

        public var errorDescription: String? {
            "SBServicesClient.Error.\(self)"
        }
    }

    public enum InterfaceOrientation {
        case unknown
        case portrait
        case portraitUpsideDown
        case landscapeLeft
        case landscapeRight

        init(raw: sbservices_interface_orientation_t) {
            switch raw {
            case SBSERVICES_INTERFACE_ORIENTATION_PORTRAIT:
                self = .portrait
            case SBSERVICES_INTERFACE_ORIENTATION_PORTRAIT_UPSIDE_DOWN:
                self = .portraitUpsideDown
            case SBSERVICES_INTERFACE_ORIENTATION_LANDSCAPE_LEFT:
                self = .landscapeLeft
            case SBSERVICES_INTERFACE_ORIENTATION_LANDSCAPE_RIGHT:
                self = .landscapeRight
            default:
                self = .unknown
            }
        }
    }

    public typealias Raw = sbservices_client_t
    public static let serviceIdentifier = SBSERVICES_SERVICE_NAME
    public static let newFunc: NewFunc = sbservices_client_new
    public static let startFunc: StartFunc = sbservices_client_start_service
    public let raw: sbservices_client_t
    public required init(raw: sbservices_client_t) { self.raw = raw }
    deinit { sbservices_client_free(raw) }

    private let encoder = PlistNodeEncoder()
    private let decoder = PlistNodeDecoder()

    // png
    public func icon(forApp bundleID: String) throws -> Data {
        try CAPI<Error>.getData { buf, rawSize in
            var size: UInt64 {
                get { .init(rawSize) }
                set { rawSize = .init(newValue) }
            }
            return sbservices_get_icon_pngdata(raw, bundleID, &buf, &size)
        }
    }

    // png
    public func wallpaper() throws -> Data {
        try CAPI<Error>.getData { buf, rawSize in
            var size: UInt64 {
                get { .init(rawSize) }
                set { rawSize = .init(newValue) }
            }
            return sbservices_get_home_screen_wallpaper_pngdata(raw, &buf, &size)
        }
    }

    public func interfaceOrientation() throws -> InterfaceOrientation {
        var orientation = SBSERVICES_INTERFACE_ORIENTATION_UNKNOWN
        try CAPI<Error>.check(sbservices_get_interface_orientation(raw, &orientation))
        return .init(raw: orientation)
    }

    public func iconState<T: Decodable>(ofType type: T.Type, format: String?) throws -> T {
        try decoder.decode(type) {
            try CAPI<Error>.check(sbservices_get_icon_state(raw, &$0, format))
        }
    }

    public func setIconState<T: Encodable>(_ state: T) throws {
        try encoder.withEncoded(state) {
            try CAPI<Error>.check(sbservices_set_icon_state(raw, $0))
        }
    }

}
