//
//  Service.swift
//  SwiftyMobileDevice
//
//  Created by Kabir Oberai on 13/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation

public protocol Service: CAPIWrapper {

    static var serviceIdentifier: String { get }

    typealias NewFunc = (
        idevice_t, lockdownd_service_descriptor_t, UnsafeMutablePointer<Raw?>?
    ) -> Error.Raw
    static var newFunc: NewFunc { get }

    typealias StartFunc = (
        idevice_t, UnsafeMutablePointer<Raw?>?, UnsafePointer<Int8>?
    ) -> Error.Raw
    static var startFunc: StartFunc { get }

    init(raw: Raw)

}

public extension Service {

    init(device: Device, service: LockdownClient.ServiceDescriptor<Self>) throws {
        var client: Raw?
        try Self.check(Self.newFunc(device.raw, service.raw, &client))
        guard let raw = client else { throw CAPIError.unexpectedNil }
        self.init(raw: raw)
    }

    init(device: Device, label: String?) throws {
        var client: Raw?
        try Self.check(Self.startFunc(device.raw, &client, label))
        guard let raw = client else { throw CAPIError.unexpectedNil }
        self.init(raw: raw)
    }

}
