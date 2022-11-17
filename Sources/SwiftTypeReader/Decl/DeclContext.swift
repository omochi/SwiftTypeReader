public protocol DeclContext: AnyObject & HashableFromIdentity & _DeclParentContextHolder {
    func findOwn(name: String, options: LookupOptions) -> (any Decl)?
}

extension DeclContext {
    public func asAnyDeclContext() -> AnyDeclContext {
        AnyDeclContext(self)
    }
}
