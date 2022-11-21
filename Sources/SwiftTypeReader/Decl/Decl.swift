import Foundation

public protocol Decl: AnyObject & HashableFromIdentity & _DeclParentContextHolder {
}

extension Decl {
    public var innermostContext: any DeclContext {
        if let self = self as? any DeclContext {
            return self
        }
        return parentContext!
    }
}
