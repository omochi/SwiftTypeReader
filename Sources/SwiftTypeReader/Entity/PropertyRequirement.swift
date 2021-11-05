import Foundation

protocol A {
    @available(macOS 12.0.0, *)
    var a: Int { mutating get async throws }
    var b: Int { get  set }
}

public struct PropertyRequirement {
    public enum Accessor: Equatable {
        case get(mutating: Bool = false, async: Bool = false, throws: Bool = false)
        case set(nonmutating: Bool = false)
        @available(macOS 12.0.0, *)
        case async
        @available(macOS 12.0.0, *)
        case `throws`
    }

    public init(
        name: String,
        typeSpecifier: TypeSpecifier,
        accessors: [Accessor],
        isStatic: Bool
    ) {
        self.name = name
        self.unresolvedType = .unresolved(typeSpecifier)
        self.accessors = accessors
        self.isStatic = isStatic
    }

    public var name: String

    public func type() throws -> SType {
        try unresolvedType.resolved()
    }

    public var unresolvedType: SType

    public var accessors: [Accessor]
    public var isStatic: Bool
}
