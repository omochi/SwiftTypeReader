public enum VarKind: String, Hashable {
    case `let`
    case `var`
}

public enum PropertyKind: Hashable {
    case stored
    case computed
}

public final class VarDecl: ValueDecl {
    public init(
        context: any DeclContext,
        modifiers: [DeclModifier],
        kind: VarKind,
        name: String,
        typeRepr: any TypeRepr
    ) {
        self.context = context
        self.modifiers = modifiers
        self.kind = kind
        self.name = name
        self.typeRepr = typeRepr
        self.accessors = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var modifiers: [DeclModifier]
    public var kind: VarKind
    public var name: String
    public var valueName: String? { name }
    public var typeRepr: any TypeRepr
    public var accessors: [AccessorDecl]

    public var propertyKind: PropertyKind {
        let areAllObservers = accessors.allSatisfy { (accessor) in
            accessor.kind.isObserver
        }

        if areAllObservers {
            return .stored
        } else {
            return .computed
        }
    }
}

extension [VarDecl] {
    public var instances: [VarDecl] {
        filter { !$0.modifiers.isStatic }
    }

    public var statics: [VarDecl] {
        filter { $0.modifiers.isStatic }
    }
}
