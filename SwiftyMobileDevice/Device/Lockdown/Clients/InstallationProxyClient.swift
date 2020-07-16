//
//  InstallationProxyClient.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 14/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation

public class InstallationProxyClient: LockdownService {

    public enum Error: CAPIError, LocalizedError {
        case unknown
        case `internal`
        case invalidArg
        case plistError
        case connFailed
        case opInProgress
        case opFailed
        case receiveTimeout
        case alreadyArchived
        case apiInternalError
        case applicationAlreadyInstalled
        case applicationMoveFailed
        case applicationSinfCaptureFailed
        case applicationSandboxFailed
        case applicationVerificationFailed
        case archiveDestructionFailed
        case bundleVerificationFailed
        case carrierBundleCopyFailed
        case carrierBundleDirectoryCreationFailed
        case carrierBundleMissingSupportedSims
        case commCenterNotificationFailed
        case containerCreationFailed
        case containerP0wnFailed
        case containerRemovalFailed
        case embeddedProfileInstallFailed
        case executableTwiddleFailed
        case existenceCheckFailed
        case installMapUpdateFailed
        case manifestCaptureFailed
        case mapGenerationFailed
        case missingBundleExecutable
        case missingBundleIdentifier
        case missingBundlePath
        case missingContainer
        case notificationFailed
        case packageExtractionFailed
        case packageInspectionFailed
        case packageMoveFailed
        case pathConversionFailed
        case restoreContainerFailed
        case seatbeltProfileRemovalFailed
        case stageCreationFailed
        case symlinkFailed
        case unknownCommand
        case itunesArtworkCaptureFailed
        case itunesMetadataCaptureFailed
        case deviceOsVersionTooLow
        case deviceFamilyNotSupported
        case packagePatchFailed
        case incorrectArchitecture
        case pluginCopyFailed
        case breadcrumbFailed
        case breadcrumbUnlockFailed
        case geojsonCaptureFailed
        case newsstandArtworkCaptureFailed
        case missingCommand
        case notEntitled
        case missingPackagePath
        case missingContainerPath
        case missingApplicationIdentifier
        case missingAttributeValue
        case lookupFailed
        case dictCreationFailed
        case installProhibited
        case uninstallProhibited
        case missingBundleVersion

        public init?(_ raw: instproxy_error_t) {
            switch raw {
            case INSTPROXY_E_SUCCESS:
                return nil
            case INSTPROXY_E_INVALID_ARG:
                self = .invalidArg
            case INSTPROXY_E_PLIST_ERROR:
                self = .plistError
            case INSTPROXY_E_CONN_FAILED:
                self = .connFailed
            case INSTPROXY_E_OP_IN_PROGRESS:
                self = .opInProgress
            case INSTPROXY_E_OP_FAILED:
                self = .opFailed
            case INSTPROXY_E_RECEIVE_TIMEOUT:
                self = .receiveTimeout
            case INSTPROXY_E_ALREADY_ARCHIVED:
                self = .alreadyArchived
            case INSTPROXY_E_API_INTERNAL_ERROR:
                self = .apiInternalError
            case INSTPROXY_E_APPLICATION_ALREADY_INSTALLED:
                self = .applicationAlreadyInstalled
            case INSTPROXY_E_APPLICATION_MOVE_FAILED:
                self = .applicationMoveFailed
            case INSTPROXY_E_APPLICATION_SINF_CAPTURE_FAILED:
                self = .applicationSinfCaptureFailed
            case INSTPROXY_E_APPLICATION_SANDBOX_FAILED:
                self = .applicationSandboxFailed
            case INSTPROXY_E_APPLICATION_VERIFICATION_FAILED:
                self = .applicationVerificationFailed
            case INSTPROXY_E_ARCHIVE_DESTRUCTION_FAILED:
                self = .archiveDestructionFailed
            case INSTPROXY_E_BUNDLE_VERIFICATION_FAILED:
                self = .bundleVerificationFailed
            case INSTPROXY_E_CARRIER_BUNDLE_COPY_FAILED:
                self = .carrierBundleCopyFailed
            case INSTPROXY_E_CARRIER_BUNDLE_DIRECTORY_CREATION_FAILED:
                self = .carrierBundleDirectoryCreationFailed
            case INSTPROXY_E_CARRIER_BUNDLE_MISSING_SUPPORTED_SIMS:
                self = .carrierBundleMissingSupportedSims
            case INSTPROXY_E_COMM_CENTER_NOTIFICATION_FAILED:
                self = .commCenterNotificationFailed
            case INSTPROXY_E_CONTAINER_CREATION_FAILED:
                self = .containerCreationFailed
            case INSTPROXY_E_CONTAINER_P0WN_FAILED:
                self = .containerP0wnFailed
            case INSTPROXY_E_CONTAINER_REMOVAL_FAILED:
                self = .containerRemovalFailed
            case INSTPROXY_E_EMBEDDED_PROFILE_INSTALL_FAILED:
                self = .embeddedProfileInstallFailed
            case INSTPROXY_E_EXECUTABLE_TWIDDLE_FAILED:
                self = .executableTwiddleFailed
            case INSTPROXY_E_EXISTENCE_CHECK_FAILED:
                self = .existenceCheckFailed
            case INSTPROXY_E_INSTALL_MAP_UPDATE_FAILED:
                self = .installMapUpdateFailed
            case INSTPROXY_E_MANIFEST_CAPTURE_FAILED:
                self = .manifestCaptureFailed
            case INSTPROXY_E_MAP_GENERATION_FAILED:
                self = .mapGenerationFailed
            case INSTPROXY_E_MISSING_BUNDLE_EXECUTABLE:
                self = .missingBundleExecutable
            case INSTPROXY_E_MISSING_BUNDLE_IDENTIFIER:
                self = .missingBundleIdentifier
            case INSTPROXY_E_MISSING_BUNDLE_PATH:
                self = .missingBundlePath
            case INSTPROXY_E_MISSING_CONTAINER:
                self = .missingContainer
            case INSTPROXY_E_NOTIFICATION_FAILED:
                self = .notificationFailed
            case INSTPROXY_E_PACKAGE_EXTRACTION_FAILED:
                self = .packageExtractionFailed
            case INSTPROXY_E_PACKAGE_INSPECTION_FAILED:
                self = .packageInspectionFailed
            case INSTPROXY_E_PACKAGE_MOVE_FAILED:
                self = .packageMoveFailed
            case INSTPROXY_E_PATH_CONVERSION_FAILED:
                self = .pathConversionFailed
            case INSTPROXY_E_RESTORE_CONTAINER_FAILED:
                self = .restoreContainerFailed
            case INSTPROXY_E_SEATBELT_PROFILE_REMOVAL_FAILED:
                self = .seatbeltProfileRemovalFailed
            case INSTPROXY_E_STAGE_CREATION_FAILED:
                self = .stageCreationFailed
            case INSTPROXY_E_SYMLINK_FAILED:
                self = .symlinkFailed
            case INSTPROXY_E_UNKNOWN_COMMAND:
                self = .unknownCommand
            case INSTPROXY_E_ITUNES_ARTWORK_CAPTURE_FAILED:
                self = .itunesArtworkCaptureFailed
            case INSTPROXY_E_ITUNES_METADATA_CAPTURE_FAILED:
                self = .itunesMetadataCaptureFailed
            case INSTPROXY_E_DEVICE_OS_VERSION_TOO_LOW:
                self = .deviceOsVersionTooLow
            case INSTPROXY_E_DEVICE_FAMILY_NOT_SUPPORTED:
                self = .deviceFamilyNotSupported
            case INSTPROXY_E_PACKAGE_PATCH_FAILED:
                self = .packagePatchFailed
            case INSTPROXY_E_INCORRECT_ARCHITECTURE:
                self = .incorrectArchitecture
            case INSTPROXY_E_PLUGIN_COPY_FAILED:
                self = .pluginCopyFailed
            case INSTPROXY_E_BREADCRUMB_FAILED:
                self = .breadcrumbFailed
            case INSTPROXY_E_BREADCRUMB_UNLOCK_FAILED:
                self = .breadcrumbUnlockFailed
            case INSTPROXY_E_GEOJSON_CAPTURE_FAILED:
                self = .geojsonCaptureFailed
            case INSTPROXY_E_NEWSSTAND_ARTWORK_CAPTURE_FAILED:
                self = .newsstandArtworkCaptureFailed
            case INSTPROXY_E_MISSING_COMMAND:
                self = .missingCommand
            case INSTPROXY_E_NOT_ENTITLED:
                self = .notEntitled
            case INSTPROXY_E_MISSING_PACKAGE_PATH:
                self = .missingPackagePath
            case INSTPROXY_E_MISSING_CONTAINER_PATH:
                self = .missingContainerPath
            case INSTPROXY_E_MISSING_APPLICATION_IDENTIFIER:
                self = .missingApplicationIdentifier
            case INSTPROXY_E_MISSING_ATTRIBUTE_VALUE:
                self = .missingAttributeValue
            case INSTPROXY_E_LOOKUP_FAILED:
                self = .lookupFailed
            case INSTPROXY_E_DICT_CREATION_FAILED:
                self = .dictCreationFailed
            case INSTPROXY_E_INSTALL_PROHIBITED:
                self = .installProhibited
            case INSTPROXY_E_UNINSTALL_PROHIBITED:
                self = .uninstallProhibited
            case INSTPROXY_E_MISSING_BUNDLE_VERSION:
                self = .missingBundleVersion
            default:
                self = .unknown
            }
        }

        public var errorDescription: String? {
            "InstallationProxyClient.Error.\(self)"
        }
    }

    public struct StatusError: LocalizedError {
        public let type: Error
        public let name: String
        public let details: String?
        public let code: Int

        init?(raw: plist_t) {
            var rawName: UnsafeMutablePointer<Int8>?
            var rawDetails: UnsafeMutablePointer<Int8>?
            var rawCode: UInt64 = 0
            guard let type = Error(instproxy_status_get_error(raw, &rawName, &rawDetails, &rawCode)),
                let name = rawName.map({ String(cString: $0) })
                else { return nil }

            self.type = type
            self.name = name
            self.details = rawDetails.map { String(cString: $0) }
            self.code = .init(rawCode)
        }

        public var errorDescription: String? {
            "\(name) (0x\(String(code, radix: 16)))\(details.map { ": \($0)" } ?? "")"
        }
    }

    public struct InstallProgress {
        public let details: String
        public let progress: Double?
    }

    // open so that extra options may be added
    open class Options: Encodable {
        public var skipUninstall: Bool?
        public var applicationSINF: Data?
        public var itunesMetadata: Data?
        public var returnAttributes: [String]?
        public var additionalOptions: [String: String] = [:]

        private enum CodingKeys: String, CodingKey {
            case skipUninstall = "SkipUninstall"
            case applicationSINF = "ApplicationSINF"
            case itunesMetadata = "iTunesMetadata"
            case returnAttributes = "ReturnAttributes"
        }

        public func encode(to encoder: Encoder) throws {
            var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
            try skipUninstall.map { try keyedContainer.encode($0, forKey: .skipUninstall) }
            try applicationSINF.map { try keyedContainer.encode($0, forKey: .applicationSINF) }
            try itunesMetadata.map { try keyedContainer.encode($0, forKey: .itunesMetadata) }
            try returnAttributes.map { try keyedContainer.encode($0, forKey: .returnAttributes) }
            try additionalOptions.encode(to: encoder)
        }

        public init(
            skipUninstall: Bool? = nil,
            applicationSINF: Data? = nil,
            itunesMetadata: Data? = nil,
            returnAttributes: [String]? = nil,
            additionalOptions: [String: String] = [:]
        ) {
            self.skipUninstall = skipUninstall
            self.applicationSINF = applicationSINF
            self.itunesMetadata = itunesMetadata
            self.returnAttributes = returnAttributes
            self.additionalOptions = additionalOptions
        }
    }

    private class InstallUserData {
        var isIncomplete = true
        let progress: (InstallProgress) -> Void
        let completion: (Result<(), Swift.Error>) -> Void
        init(
            progress: @escaping (InstallProgress) -> Void,
            completion: @escaping (Result<(), Swift.Error>) -> Void
        ) {
            self.progress = progress
            self.completion = completion
        }
    }

    public typealias Raw = instproxy_client_t
    public static let serviceIdentifier = INSTPROXY_SERVICE_NAME
    public static let newFunc: NewFunc = instproxy_client_new
    public static let startFunc: StartFunc = instproxy_client_start_service
    public let raw: instproxy_client_t
    public required init(raw: instproxy_client_t) { self.raw = raw }
    deinit { instproxy_client_free(raw) }

    private let encoder = PlistNodeEncoder()

    public func install(
        package: URL,
        options: Options,
        progress: @escaping (InstallProgress) -> Void,
        completion: @escaping (Result<(), Swift.Error>) -> Void
    ) {
        let rawUserData = Unmanaged
            .passRetained(InstallUserData(progress: progress, completion: completion))
            .toOpaque()

        if let error = try? Error(package.withUnsafeFileSystemRepresentation { path in
            try encoder.withEncoded(options) { rawOptions in
                instproxy_install(raw, path, rawOptions, { _, rawStatus, rawUserData in
                    let unmanagedUserData = Unmanaged<InstallUserData>.fromOpaque(rawUserData!)
                    let userData = unmanagedUserData.takeUnretainedValue()

                    func complete(_ result: Result<(), Swift.Error>) {
                        userData.completion(result)
                        unmanagedUserData.release()
                    }

                    if let error = StatusError(raw: rawStatus!) {
                        return complete(.failure(error))
                    }

                    var rawStatusName: UnsafeMutablePointer<Int8>?
                    instproxy_status_get_name(rawStatus, &rawStatusName)
                    guard let statusName = rawStatusName.map({ String(cString: $0) })
                        else { return complete(.failure(Error.unknown)) }

                    if statusName == "Complete" {
                        return complete(.success(()))
                    }

                    var rawPercent: Int32 = -1
                    instproxy_status_get_percent_complete(rawStatus, &rawPercent)
                    let progress = rawPercent >= 0 ? (Double(rawPercent) / 100) : nil

                    userData.progress(.init(details: statusName, progress: progress))
                }, rawUserData)
            }
        }) {
            completion(.failure(error))
        }
    }

}

