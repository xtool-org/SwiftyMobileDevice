public enum ConnectionType {
    case usb
    case network
}

public enum LookupMode: Hashable {
    case only(ConnectionType)
    case both(preferring: ConnectionType)
}
