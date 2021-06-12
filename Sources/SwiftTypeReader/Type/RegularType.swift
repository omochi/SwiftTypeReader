import Foundation

public enum RegularType {
    case `struct`(StructType)
    case `enum`(EnumType)
    case `protocol`(ProtocolType)

    public var `struct`: StructType? {
        guard case .struct(let t) = self else {
            return nil
        }
        return t
    }

    public var `enum`: EnumType? {
        guard case .enum(let t) = self else {
            return nil
        }
        return t
    }

    public var `protocol`: ProtocolType? {
        guard case .protocol(let t) = self else {
            return nil
        }
        return t
    }

    public var module: Module? {
        switch self {
        case .struct(let t): return t.module
        case .enum(let t): return t.module
        case .protocol(let t): return t.module
        }
    }

    public var file: URL? {
        switch self {
        case .struct(let t): return t.file
        case .enum(let t): return t.file
        case .protocol(let t): return t.file
        }
    }

    public var name: String {
        switch self {
        case .struct(let t): return t.name
        case .enum(let t): return t.name
        case .protocol(let t): return t.name
        }
    }

    public func genericArguments() throws -> [SType] {
        switch self {
        case .struct(let t):
            return try t.genericArguments()
        case .enum(let t):
            return try t.genericArguments()
        case .protocol: return []
        }
    }

    public var genericArgumentSpecifiers: [TypeSpecifier] {
        switch self {
        case .struct(let t):
            return t.unresolvedGenericArguments.asSpecifiers()
        case .enum(let t):
            return t.unresolvedGenericArguments.asSpecifiers()
        case .protocol: return []
        }
    }

    public func asSpecifier() -> TypeSpecifier {
        TypeSpecifier(
            module: module,
            file: file,
            name: name,
            genericArguments: genericArgumentSpecifiers
        )
    }

    public func applyingGenericArguments(_ args: [SType]) throws -> RegularType {
        switch self {
        case .struct(var t):
            t.setGenericArguments(args)
            return .struct(t)
        case .enum(var t):
            t.setGenericArguments(args)
            return .enum(t)
        case .protocol:
            throw MessageError("protocol can't be applied generic arguments")
        }
    }
    
}
