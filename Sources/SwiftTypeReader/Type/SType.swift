import Foundation

/*
 S prefix can avoid problem from name `Type` that
 we can't write `SwiftTypeReader.Type`.
 S means Swift.

 This type hides cache state mutability.
*/

public struct SType: CustomStringConvertible {
    public enum State {
        case resolved(RegularType)
        case unresolved(TypeSpecifier)
    }

    let box: MutableBox<State>

    init(_ box: MutableBox<State>) {
        self.box = box
    }

    public var state: State {
        get { box.value }
    }

    public init(_ state: State) {
        self.init(MutableBox(state))
    }

    public var regular: RegularType? {
        guard case .resolved(let x) = state else { return nil }
        return x
    }

    public var `struct`: StructType? {
        regular?.struct
    }

    public var `enum`: EnumType? {
        regular?.enum
    }

    public var `protocol`: ProtocolType? {
        regular?.protocol
    }

    public var `genericParameter`: GenericParameterType? {
        regular?.genericParameter
    }

    public var `unresolved`: TypeSpecifier? {
        guard case .unresolved(let x) = state else { return nil }
        return x
    }

    public func resolved() throws -> SType {
        if case .unresolved(let s) = state {
            // safe even if shared
            box.value = try s.resolve().state
        }
        return self
    }

    public var name: String {
        switch state {
        case .resolved(let t): return t.name
        case .unresolved(let s): return s.lastElement.name
        }
    }

    public func asSpecifier() -> TypeSpecifier {
        switch state {
        case .resolved(let t): return t.asSpecifier()
        case .unresolved(let s): return s
        }
    }

    public func genericArguments() throws -> [SType] {
        switch state {
        case .resolved(let t): return try t.genericArguments()
        case .unresolved(let t): return try t.lastElement.genericArguments()
        }
    }

    public var genericArgumentSpecifiers: [TypeSpecifier] {
        switch state {
        case .resolved(let t): return t.genericArgumentSpecifiers
        case .unresolved(let t): return t.lastElement.genericArgumentSpecifiers
        }
    }

    public func applyingGenericArguments(_ args: [SType]) throws -> SType {
        switch state {
        case .resolved(var t):
            t = try t.applyingGenericArguments(args)
            return .resolved(t)
        case .unresolved:
            throw MessageError("unresolved type can't be applied generic arguments")
        }
    }

    public var description: String {
        switch state {
        case .resolved(let t): return t.description
        case .unresolved(let s): return s.description
        }
    }

    public static func `struct`(_ t: StructType) -> SType {
        .init(.resolved(.struct(t)))
    }

    public static func `enum`(_ t: EnumType) -> SType {
        .init(.resolved(.enum(t)))
    }

    public static func `protocol`(_ t: ProtocolType) -> SType {
        .init(.resolved(.protocol(t)))
    }

    public static func genericParameter(_ t: GenericParameterType) -> SType {
        .init(.resolved(.genericParameter(t)))
    }

    public static func resolved(_ t: RegularType) -> SType {
        .init(.resolved(t))
    }

    public static func unresolved(_ s: TypeSpecifier) -> SType {
        .init(.unresolved(s))
    }
}
