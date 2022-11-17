public protocol DeclContext: AnyObject & HashableFromIdentity & _DeclParentContextHolder {
    func findOwn(name: String, options: LookupOptions) -> (any Decl)?
}
