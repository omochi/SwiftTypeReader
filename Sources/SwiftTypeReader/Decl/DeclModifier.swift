public enum DeclModifier: String, Hashable {
    case `static` = "static"
    case `class` = "class"
    case `nonmutating`
    case `mutating`
    case `consuming` = "__consuming"
    case `throws`
    case `rethrows`
    case `async`
    case `reasync`
    case `public`
    case `private`
    case `fileprivate`
    case `internal`
    case `open`

    public var isStatic: Bool {
        switch self {
        case .`static`, .`class`: return true
        default: return false
        }
    }
}

extension [DeclModifier] {
    public var isStatic: Bool {
        contains { $0.isStatic }
    }
}
