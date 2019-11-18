//
//  AFCClient.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 13/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation

public class AFCClient: Service {

    public enum Error: CAPIWrapperError {
        case unknown
        case `internal`
        case opHeaderInvalid
        case noResources
        case readError
        case writeError
        case unknownPacketType
        case invalidArg
        case objectNotFound
        case objectIsDir
        case permDenied
        case serviceNotConnected
        case opTimeout
        case tooMuchData
        case endOfData
        case opNotSupported
        case objectExists
        case objectBusy
        case noSpaceLeft
        case opWouldBlock
        case ioError
        case opInterrupted
        case opInProgress
        case internalError
        case muxError
        case noMem
        case notEnoughData
        case dirNotEmpty
        case forceSignedType

        public init?(_ raw: afc_error_t) {
            switch raw {
            case AFC_E_SUCCESS:
                return nil
            case AFC_E_OP_HEADER_INVALID:
                self = .opHeaderInvalid
            case AFC_E_NO_RESOURCES:
                self = .noResources
            case AFC_E_READ_ERROR:
                self = .readError
            case AFC_E_WRITE_ERROR:
                self = .writeError
            case AFC_E_UNKNOWN_PACKET_TYPE:
                self = .unknownPacketType
            case AFC_E_INVALID_ARG:
                self = .invalidArg
            case AFC_E_OBJECT_NOT_FOUND:
                self = .objectNotFound
            case AFC_E_OBJECT_IS_DIR:
                self = .objectIsDir
            case AFC_E_PERM_DENIED:
                self = .permDenied
            case AFC_E_SERVICE_NOT_CONNECTED:
                self = .serviceNotConnected
            case AFC_E_OP_TIMEOUT:
                self = .opTimeout
            case AFC_E_TOO_MUCH_DATA:
                self = .tooMuchData
            case AFC_E_END_OF_DATA:
                self = .endOfData
            case AFC_E_OP_NOT_SUPPORTED:
                self = .opNotSupported
            case AFC_E_OBJECT_EXISTS:
                self = .objectExists
            case AFC_E_OBJECT_BUSY:
                self = .objectBusy
            case AFC_E_NO_SPACE_LEFT:
                self = .noSpaceLeft
            case AFC_E_OP_WOULD_BLOCK:
                self = .opWouldBlock
            case AFC_E_IO_ERROR:
                self = .ioError
            case AFC_E_OP_INTERRUPTED:
                self = .opInterrupted
            case AFC_E_OP_IN_PROGRESS:
                self = .opInProgress
            case AFC_E_INTERNAL_ERROR:
                self = .internalError
            case AFC_E_MUX_ERROR:
                self = .muxError
            case AFC_E_NO_MEM:
                self = .noMem
            case AFC_E_NOT_ENOUGH_DATA:
                self = .notEnoughData
            case AFC_E_DIR_NOT_EMPTY:
                self = .dirNotEmpty
            case AFC_E_FORCE_SIGNED_TYPE:
                self = .forceSignedType
            default: self = .unknown
            }
        }
    }

    public enum LinkType {
        case hardlink
        case symlink

        var raw: afc_link_type_t {
            switch self {
            case .hardlink: return AFC_HARDLINK
            case .symlink: return AFC_SYMLINK
            }
        }
    }

    public class File {
        public enum Mode {
            /// `r` (`O_RDONLY`)
            case readOnly
            /// `r+` (`O_RDWR | O_CREAT`)
            case readWrite
            /// `w` (`O_WRONLY | O_CREAT | O_TRUNC`)
            case writeOnly
            /// `w+` (`O_RDWR | O_CREAT | O_TRUNC`)
            case readWriteTruncate
            /// `a` (`O_WRONLY | O_APPEND | O_CREAT`)
            case append
            /// `a+` (`O_RDWR | O_APPEND | O_CREAT`)
            case readAppend

            var raw: afc_file_mode_t {
                switch self {
                case .readOnly: return AFC_FOPEN_RDONLY
                case .readWrite: return AFC_FOPEN_RW
                case .writeOnly: return AFC_FOPEN_WRONLY
                case .readWriteTruncate: return AFC_FOPEN_WR
                case .append: return AFC_FOPEN_APPEND
                case .readAppend: return AFC_FOPEN_RDAPPEND
                }
            }
        }

        public enum LockOperation {
            case shared
            case exclusive
            case unlock

            var raw: afc_lock_op_t {
                switch self {
                case .shared: return AFC_LOCK_SH
                case .exclusive: return AFC_LOCK_EX
                case .unlock: return AFC_LOCK_UN
                }
            }
        }

        public enum Whence {
            case start
            case current
            case end

            var raw: Int32 {
                switch self {
                case .start: return SEEK_SET
                case .current: return SEEK_CUR
                case .end: return SEEK_END
                }
            }
        }

        public let client: AFCClient
        let handle: UInt64
        init?(client: AFCClient, handle: UInt64) {
            guard handle != 0 else { return nil }
            self.client = client
            self.handle = handle
        }
        deinit { afc_file_close(client.raw, handle) }

        public func lock(operation: LockOperation) throws {
            try AFCClient.check(afc_file_lock(client.raw, handle, operation.raw))
        }

        public func read(maxLength: Int) throws -> Data {
            try AFCClient.getData(maxLength: maxLength) { data, received in
                afc_file_read(client.raw, handle, data, .init(maxLength), &received)
            }
        }

        public func write(_ data: Data) throws -> Int {
            var written: UInt32 = 0
            try data.withUnsafeBytes { bytes in
                let bound = bytes.bindMemory(to: Int8.self)
                try AFCClient.check(
                    afc_file_write(client.raw, handle, bound.baseAddress, .init(bound.count), &written)
                )
            }
            return .init(written)
        }

        public func seek(offset: Int, from whence: Whence) throws {
            try AFCClient.check(afc_file_seek(client.raw, handle, .init(offset), whence.raw))
        }

        public func tell() throws -> Int {
            var position: UInt64 = 0
            try AFCClient.check(afc_file_tell(client.raw, handle, &position))
            return .init(position)
        }

        public func truncate(to newSize: Int) throws {
            try AFCClient.check(afc_file_truncate(client.raw, handle, .init(newSize)))
        }
    }

    public static let serviceIdentifier = AFC_SERVICE_NAME
    public static let newFunc: NewFunc = afc_client_new
    public static let startFunc: StartFunc = afc_client_start_service
    public let raw: afc_client_t
    public required init(raw: afc_client_t) { self.raw = raw }
    deinit { afc_client_free(raw) }

    public func deviceInfo() throws -> [String: String] {
        try Self.getDictionary(
            parseFn: { afc_get_device_info(raw, &$0) },
            freeFn: { afc_dictionary_free($0) }
        )
    }

    public func contentsOfDirectory(at url: URL) throws -> [String] {
        try url.withUnsafeFileSystemRepresentation { path in
            try Self.getNullTerminatedArray(
                parseFn: { afc_read_directory(raw, path, &$0) },
                freeFn: { afc_dictionary_free($0) }
            )
        }
    }

    public func fileInfo(for url: URL) throws -> [String: String] {
        try url.withUnsafeFileSystemRepresentation { path in
            try Self.getDictionary(
                parseFn: { afc_get_file_info(raw, path, &$0) },
                freeFn: { afc_dictionary_free($0) }
            )
        }
    }

    public func fileExists(at url: URL) throws -> Bool {
        do {
            _ = try fileInfo(for: url)
        } catch let error as Error where error == .objectNotFound {
            return false
        } catch {
            throw error
        }
        return true
    }

    public func open(_ url: URL, mode: File.Mode) throws -> File {
        var handle: UInt64 = 0
        try url.withUnsafeFileSystemRepresentation { path in
            try Self.check(afc_file_open(raw, path, mode.raw, &handle))
        }
        guard let file = File(client: self, handle: handle)
            else { throw Error.internal }
        return file
    }

    public func removeItem(at url: URL) throws {
        try url.withUnsafeFileSystemRepresentation {
            try Self.check(afc_remove_path(raw, $0))
        }
    }

    public func moveItem(at url: URL, to newURL: URL) throws {
        try url.withUnsafeFileSystemRepresentation { path in
            try newURL.withUnsafeFileSystemRepresentation { newPath in
                try Self.check(afc_rename_path(raw, path, newPath))
            }
        }
    }

    public func createDirectory(at url: URL) throws {
        try url.withUnsafeFileSystemRepresentation { path in
            try Self.check(afc_make_directory(raw, path))
        }
    }

    public func truncateFile(at url: URL, to newSize: Int) throws {
        try url.withUnsafeFileSystemRepresentation { path in
            try Self.check(afc_truncate(raw, path, .init(newSize)))
        }
    }

    public func linkItem(at url: URL, to newURL: URL, type: LinkType) throws {
        try url.withUnsafeFileSystemRepresentation { path in
            try newURL.withUnsafeFileSystemRepresentation { newPath in
                try Self.check(afc_make_link(raw, type.raw, path, newPath))
            }
        }
    }

    public func setTime(at url: URL, to date: Date) throws {
        let ns = UInt64(date.timeIntervalSince1970 * 1_000_000_000)
        try url.withUnsafeFileSystemRepresentation { path in
            try Self.check(afc_set_file_time(raw, path, ns))
        }
    }

    public func removeItemAndContents(at url: URL) throws {
        try url.withUnsafeFileSystemRepresentation { path in
            try Self.check(afc_remove_path_and_contents(raw, path))
        }
    }

}
