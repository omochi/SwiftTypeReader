public protocol ResolvableProtocol {
    associatedtype ResolvedType

    func resolvedOrNone() -> ResolvedType?
}

public protocol AlwaysResolvableProtocol: ResolvableProtocol {
    func resolved() -> ResolvedType
}

extension AlwaysResolvableProtocol {
    public func resolvedOrNone() -> ResolvedType? {
        resolved()
    }
}

public final class Resolvable<Unresolved: ResolvableProtocol> {
    public enum Value {
        case resolved(Unresolved.ResolvedType)
        case unresolved(Unresolved)
    }

    public var value: Value

    public init(unresolved: Unresolved) {
        self.value = .unresolved(unresolved)
    }

    public func resolvedOrNone() -> Unresolved.ResolvedType? {
        switch value {
        case .resolved(let r): return r
        case .unresolved(let u):
            guard let r = u.resolvedOrNone() else { return nil }
            value = .resolved(r)
            return r
        }
    }

    public func resolved() -> Unresolved.ResolvedType where
        Unresolved: AlwaysResolvableProtocol
    {
        switch value {
        case .resolved(let r): return r
        case .unresolved(let u):
            let r = u.resolved()
            value = .resolved(r)
            return r
        }
    }

}
