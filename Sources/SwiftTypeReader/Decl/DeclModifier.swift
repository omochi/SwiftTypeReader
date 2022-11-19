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
}
