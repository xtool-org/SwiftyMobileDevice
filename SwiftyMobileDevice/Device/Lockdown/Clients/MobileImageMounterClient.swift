//
//  MobileImageMounterClient.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 21/03/21.
//  Copyright © 2021 Kabir Oberai. All rights reserved.
//

import Foundation
import libimobiledevice
import plist

public class MobileImageMounterClient: LockdownService {

    public enum Error: CAPIError, LocalizedError {
        case unknown
        case invalidArg
        case plistError
        case connFailed
        case commandFailed
        case deviceLocked

        public init?(_ raw: mobile_image_mounter_error_t) {
            switch raw {
            case MOBILE_IMAGE_MOUNTER_E_SUCCESS:
                return nil
            case MOBILE_IMAGE_MOUNTER_E_INVALID_ARG:
                self = .invalidArg
            case MOBILE_IMAGE_MOUNTER_E_PLIST_ERROR:
                self = .plistError
            case MOBILE_IMAGE_MOUNTER_E_CONN_FAILED:
                self = .connFailed
            case MOBILE_IMAGE_MOUNTER_E_COMMAND_FAILED:
                self = .commandFailed
            case MOBILE_IMAGE_MOUNTER_E_DEVICE_LOCKED:
                self = .deviceLocked
            default:
                self = .unknown
            }
        }

        public var errorDescription: String? {
            "MobileImageMounterClient.Error.\(self)"
        }
    }

    public typealias Raw = mobile_image_mounter_client_t
    public static let serviceIdentifier = MOBILE_IMAGE_MOUNTER_SERVICE_NAME
    public static let newFunc: NewFunc = mobile_image_mounter_new
    public static let startFunc: StartFunc = mobile_image_mounter_start_service
    public let raw: mobile_image_mounter_client_t
    public required init(raw: mobile_image_mounter_client_t) { self.raw = raw }
    deinit {
        mobile_image_mounter_hangup(raw)
        mobile_image_mounter_free(raw)
    }

    private let decoder = PlistNodeDecoder()

    public func lookup<T: Decodable>(imageType: String, resultType: T.Type) throws -> T {
        try decoder.decode(resultType) {
            try CAPI<Error>.check(mobile_image_mounter_lookup_image(raw, imageType, &$0))
        }
    }

    // the caller must open/close the stream themselves.
    public func upload(imageType: String, file: InputStream, size: Int, signature: Data?) throws {
        let userData = Unmanaged.passRetained(file)
        let finalSig = signature ?? Data()
        try finalSig.withUnsafeBytes { (buf: UnsafeRawBufferPointer) in
            let bound = buf.bindMemory(to: Int8.self)
            try CAPI<Error>.check(
                mobile_image_mounter_upload_image(
                    raw, imageType, size, bound.baseAddress!, UInt16(bound.count),
                    { chunk, size, rawUserData in
                        let file = Unmanaged<InputStream>.fromOpaque(rawUserData!).takeUnretainedValue()
                        let bytesRead = file.read(chunk!.assumingMemoryBound(to: UInt8.self), maxLength: size)
                        return bytesRead == 0 ? -1 : bytesRead
                    }, userData.toOpaque()
                )
            )
        }
        userData.release()
    }

    public func mount<T: Decodable>(
        imageType: String, imageURL: URL? = nil, signature: Data, resultType: T.Type
    ) throws -> T {
        // the url is ignored on iOS >= 7
        let url = imageURL ?? URL(fileURLWithPath: "/private/var/mobile/Media/PublicStaging/staging.dimage")
        return try url.withUnsafeFileSystemRepresentation { destRaw in
            try signature.withUnsafeBytes { sigBuf in
                let sigBound = sigBuf.bindMemory(to: Int8.self)
                return try decoder.decode(resultType) {
                    try CAPI<Error>.check(
                        mobile_image_mounter_mount_image(
                            raw, destRaw, sigBound.baseAddress, UInt16(sigBound.count), imageType, &$0
                        )
                    )
                }
            }
        }
    }

}
