public protocol HashableFromIdentity: AnyObject & Hashable {}

extension HashableFromIdentity {
    public static func ==(a: Self, b: Self) -> Bool {
        a === b
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
