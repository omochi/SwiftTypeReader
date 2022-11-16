/*
 Hashable erasure for heterogeneous dictionary key.
 This type mangles type id into hash value unlike AnyHashable doesn't.
 */

struct AnyKey: Hashable {
    public var value: any Hashable

    public init<T: Hashable>(_ value: T) {
        self.value = value
    }

    public static func ==(a: AnyKey, b: AnyKey) -> Bool {
        self.equals(a.value, b.value)
    }

    private static func equals<A, B>(_ a: A, _ b: B) -> Bool
        where A: Equatable, B: Equatable
    {
        guard A.self == B.self,
              let b = b as? A else { return false }
        return a == b
    }

    public func hash(into hasher: inout Hasher) {
        hash(value, into: &hasher)
    }

    private func hash<T>(_ value: T, into hasher: inout Hasher) where T: Hashable {
        hasher.combine(ObjectIdentifier(T.self))
        hasher.combine(value)
    }
}

