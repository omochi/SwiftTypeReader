import Foundation

/*
 S prefix can avoid problem from name `Type` that
 we can't write `SwiftTypeReader.Type`.
 S means Swift.
*/

public enum SType: CustomStringConvertible {
    case `struct`(StructType)
    case `enum`(EnumType)
    case unresolved(UnresolvedType)

    public var `struct`: StructType? {
        guard case .struct(let x) = self else { return nil }
        return x
    }

    public var `enum`: EnumType? {
        guard case .enum(let x) = self else { return nil }
        return x
    }

    public var `unresolved`: UnresolvedType? {
        guard case .unresolved(let x) = self else { return nil }
        return x
    }

    public var name: String {
        switch self {
        case .struct(let st): return st.name
        case .enum(let et): return et.name
        case .unresolved(let ut): return ut.name
        }
    }

    public var file: URL? {
        switch self {
        case .struct(let st): return st.file
        case .enum(let et): return et.file
        case .unresolved(let ut): return ut.file
        }
    }

    public var genericArguments: [SType] {
        get {
            switch self {
            case .struct(let st): return st.genericsArguments
            case .enum(let et): return et.genericsArguments
            case .unresolved(let ut): return ut.genericArguments
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
            case .unresolved(var ut):
                ut.genericArguments = newValue
                self = .unresolved(ut)
            }
        }
    }

    public func asSpecifier() -> TypeSpecifier {
        switch self {
        case .unresolved(let ut): return ut.specifier
        default:
            return TypeSpecifier(
                name: name,
                genericArguments: genericArguments.map { $0.asSpecifier() }
            )
        }
    }

    public var description: String {
        asSpecifier().description
    }
}
