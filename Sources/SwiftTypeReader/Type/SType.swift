import Foundation

/*
 S prefix can avoid problem from name `Type` that
 we can't write `SwiftTypeReader.Type`.
 S means Swift.

 This type hides cache state mutability.
*/

public struct SType: CustomStringConvertible {
    enum State {
        case resolved(RegularType)
        case unresolved(TypeSpecifier)
    }

    let box: MutableBox<State>

    init(_ box: MutableBox<State>) {
        self.box = box
    }

    var state: State {
        get { box.value }
        nonmutating set { box.value = newValue }
    }

    init(_ state: State) {
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

    public var `unresolved`: TypeSpecifier? {
        guard case .unresolved(let x) = state else { return nil }
        return x
    }

    public func resolved() throws -> SType {
        if case .unresolved(let s) = state {
            state = try s.resolve().state
        }
        return self
    }

    public var name: String {
        switch state {
        case .resolved(let t): return t.name
        case .unresolved(let s): return s.name
        }
    }

    public func asSpecifier() -> TypeSpecifier {
        switch state {
        case .unresolved(let s): return s
        case .resolved(let t): return t.asSpecifier()
        }
    }

    public func applyingGenericArguments(_ args: [SType]) throws -> SType {
        switch state {
        case .resolved(var t):
            t = try t.applyingGenericArguments(args)
            return .resolved(t)
        case .unresolved(var s):
            s.genericArguments = args.map { $0.asSpecifier() }
            return .unresolved(s)
        }
    }

    public var description: String {
        asSpecifier().description
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

    public static func resolved(_ t: RegularType) -> SType {
        .init(.resolved(t))
    }

    public static func unresolved(_ s: TypeSpecifier) -> SType {
        .init(.unresolved(s))
    }
}
