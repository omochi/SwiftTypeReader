import Foundation

public protocol Decl: AnyObject & HashableFromIdentity & _DeclParentContextHolder {
}

extension Decl {
    public func asAnyDecl() -> AnyDecl {
        AnyDecl(self)
    }
}
