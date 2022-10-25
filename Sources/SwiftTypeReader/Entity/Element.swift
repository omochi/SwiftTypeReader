public enum Element {
    case module(Module)
    case type(SType)

    public var module: Module? {
        switch self {
        case .module(let x): return x
        default: return nil
        }
    }

    public var type: SType? {
        switch self {
        case .type(let x): return x
        default: return nil
        }
    }
}
