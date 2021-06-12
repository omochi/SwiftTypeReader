import Foundation

/*
 This type hides cache mutability.
 */

public struct TypeCollection {
    enum State {
        case resolved([SType])
        case unresolved([TypeSpecifier])
    }

    let box: MutableBox<State>

    init(_ box: MutableBox<State>) {
        self.box = box
    }

    init(_ state: State) {
        self.init(MutableBox(state))
    }

    var state: State {
        get { box.value }
    }

    public init(_ specifiers: [TypeSpecifier]) {
        self = .unresolved(specifiers)
    }

    public init(_ types: [SType]) {
        self = .resolved(types)
    }

    public func resolved() throws -> [SType] {
        if case .unresolved(let ss) = state {
            // safe even if shared
            box.value = .resolved(
                try ss.map { try $0.resolve() }
            )
        }
        return self.asTypes()
    }

    public func asTypes() -> [SType] {
        switch state {
        case .resolved(let ts): return ts
        case .unresolved(let ss):
            return ss.map { (s) in .unresolved(s) }
        }
    }

    public func asSpecifiers() -> [TypeSpecifier] {
        switch state {
        case .unresolved(let s): return s
        case .resolved(let ts):
            return ts.map { (t) in
                t.asSpecifier()
            }
        }
    }

    public static func unresolved(_ ss: [TypeSpecifier]) -> TypeCollection {
        TypeCollection(.unresolved(ss))
    }

    public static func resolved(_ ts: [SType]) -> TypeCollection {
        TypeCollection(.resolved(ts))
    }
}

extension TypeCollection: Collection {
    public typealias Element = SType
    public typealias Index = Int

    public var startIndex: Int { 0 }

    public var endIndex: Int {
        switch state {
        case .resolved(let ts): return ts.count
        case .unresolved(let ss): return ss.count
        }
    }

    public subscript(position: Int) -> SType {
        get {
            switch state {
            case .resolved(let ts): return ts[position]
            case .unresolved(let ss): return .unresolved(ss[position])
            }
        }
    }

    public func index(after i: Int) -> Int {
        i + 1
    }

}
