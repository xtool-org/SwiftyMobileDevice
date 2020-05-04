//
//  LockdownService.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 13/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation

public protocol LockdownService {

    associatedtype Error: CAPIError

    associatedtype Raw
    var raw: Raw { get }

    static var serviceIdentifier: String { get }

    static var newFunc: NewFunc { get }
    static var startFunc: StartFunc { get }

    init(raw: Raw)

}

public extension LockdownService {

    typealias NewFunc = (
        idevice_t, lockdownd_service_descriptor_t, UnsafeMutablePointer<Raw?>?
    ) -> Error.Raw

    typealias StartFunc = (
        idevice_t, UnsafeMutablePointer<Raw?>?, UnsafePointer<Int8>?
    ) -> Error.Raw

    init(device: Device, service: LockdownClient.ServiceDescriptor<Self>) throws {
        var client: Raw?
        try CAPI<Error>.check(Self.newFunc(device.raw, service.raw, &client))
        guard let raw = client else { throw CAPIGenericError.unexpectedNil }
        self.init(raw: raw)
    }

    init(device: Device, label: String?) throws {
        var client: Raw?
        try CAPI<Error>.check(Self.startFunc(device.raw, &client, label))
        guard let raw = client else { throw CAPIGenericError.unexpectedNil }
        self.init(raw: raw)
    }

}
