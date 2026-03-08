public struct AMFIClient {
    public let propertyListClient: PropertyListClient

    public init(propertyListClient: PropertyListClient) {
        self.propertyListClient = propertyListClient
    }

    public init(
        device: Device,
        lockdownClient: LockdownClient,
    ) throws {
        self.propertyListClient = try PropertyListClient(
            device: device,
            lockdownClient: lockdownClient,
            serviceIdentifier: "com.apple.amfi.lockdown"
        )
    }

    public init(
        device: Device,
        label: String?,
    ) throws {
        let lockdown = try LockdownClient(device: device, label: label, performHandshake: true)
        try self.init(device: device, lockdownClient: lockdown)
    }

    public enum Error: Swift.Error {
        case serviceError(String)
        case unknown
    }

    public enum Action: UInt, Encodable {
        case reveal = 0
        case arm = 1
        case enable = 2
    }

    private struct Command: Encodable {
        var action: Action
    }

    private struct Response: Decodable {
        var error: String?
        var success: Bool?

        private enum CodingKeys: String, CodingKey {
            case error = "Error"
            case success
        }
    }

    public func perform(action: Action) throws {
        try propertyListClient.send(Command(action: .reveal), format: .xml)
        let response = try propertyListClient.receive(type: Response.self)
        if let error = response.error {
            throw Error.serviceError(error)
        }
        if response.success != true {
            throw Error.unknown
        }
    }
}
