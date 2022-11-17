import Foundation

public protocol Decl: AnyObject & Hashable & _DeclParentContextHolder {
}

extension Decl {
    public static func ==(a: Self, b: Self) -> Bool {
        a === b
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public func asAnyDecl() -> AnyDecl {
        AnyDecl(self)
    }
}
