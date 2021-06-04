public protocol UnresolvedProtocol {
    associatedtype ResolvedType

    func resolved() -> ResolvedType?
}

public final class Resolvable<Unresolved: UnresolvedProtocol> {
    public enum Value {
        case resolved(Unresolved.ResolvedType)
        case unresolved(Unresolved)
    }

    public var value: Value

    public init(unresolved: Unresolved) {
        self.value = .unresolved(unresolved)
    }

    public func resolved() -> Unresolved.ResolvedType? {
        switch value {
        case .resolved(let r): return r
        case .unresolved(let u):
            guard let r = u.resolved() else { return nil }
            value = .resolved(r)
            return r
        }
    }
}
