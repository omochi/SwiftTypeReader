public protocol UnresolvedProtocol {
    associatedtype ResolvedType

    func resolved() -> ResolvedType?
}

public enum Resolvable<Unresolved: UnresolvedProtocol> {
    case resolved(Unresolved.ResolvedType)
    case unresolved(Unresolved)

    public func resolved() -> Unresolved.ResolvedType? {
        switch self {
        case .resolved(let r): return r
        case .unresolved(let u): return u.resolved()
        }
    }
}
