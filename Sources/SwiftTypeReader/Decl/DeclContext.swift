public protocol DeclContext: AnyObject & HashableFromIdentity & _DeclParentContextHolder {
    func find(name: String, options: LookupOptions) -> (any Decl)?
}

extension DeclContext {
    public func findType(name: String) -> (any Decl)? {
        find(name: name, options: LookupOptions(value: false, type: true))
    }
}
