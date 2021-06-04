public enum Type: CustomStringConvertible {
    case `struct`(StructType)
    case `enum`(EnumType)

    public var `struct`: StructType? {
        guard case .struct(let x) = self else { return nil }
        return x
    }

    public var `enum`: EnumType? {
        guard case .enum(let x) = self else { return nil }
        return x
    }

    public var name: String {
        switch self {
        case .struct(let st): return st.name
        case .enum(let et): return et.name
        }
    }

    public var genericArguments: [Type] {
        get {
            switch self {
            case .struct(let st): return st.genericsArguments
            case .enum(let et): return et.genericsArguments
            }
        }
        set {
            switch self {
            case .struct(var st):
                st.genericsArguments = newValue
                self = .struct(st)
            case .enum(var et):
                et.genericsArguments = newValue
                self = .enum(et)
            }
        }
    }

    public func asSpecifier() -> TypeSpecifier {
        TypeSpecifier(
            name: name,
            genericArguments: genericArguments.map { $0.asSpecifier() }
        )
    }

    public var description: String {
        asSpecifier().description
    }
}
