public enum ConnectionType: Sendable {
    case usb
    case network
}

public enum LookupMode: Hashable, Sendable {
    case only(ConnectionType)
    case both(preferring: ConnectionType)
}
