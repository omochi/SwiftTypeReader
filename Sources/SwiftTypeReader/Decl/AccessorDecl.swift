public enum AccessorKind: String {
    case get
    case set
    case read = "_read"
    case modify = "_modify"
    case willSet
    case didSet

    public var isObserver: Bool {
        switch self {
        case .get, .set, .read, .modify: return false
        case .willSet, .didSet: return true
        }
    }
}

public final class AccessorDecl: ValueDecl {
    public init(
        `var`: VarDecl,
        attributes: [Attribute],
        modifiers: [DeclModifier],
        kind: AccessorKind
    ) {
        self.var = `var`
        self.attributes = attributes
        self.modifiers = modifiers
        self.kind = kind
    }

    public unowned var `var`: VarDecl
    public var parentContext: (any DeclContext)? { `var`.parentContext }
    public var attributes: [Attribute]
    public var modifiers: [DeclModifier]
    public var kind: AccessorKind
    public var valueName: String? { nil }
}
