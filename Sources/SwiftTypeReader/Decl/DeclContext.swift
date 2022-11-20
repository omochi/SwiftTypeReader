public protocol DeclContext: AnyObject & HashableFromIdentity & _DeclParentContextHolder {
    func find(name: String, options: LookupOptions) -> (any Decl)?
}

extension DeclContext {
    public func find(name: String) -> (any Decl)? {
        find(name: name, options: LookupOptions(value: true, type: true))
    }

    public func findType(name: String) -> (any TypeDecl)? {
        guard let decl = find(
            name: name,
            options: LookupOptions(value: false, type: true)
        ) else { return nil }
        return (decl as! any TypeDecl)
    }

    public var selfInterfaceType: (any SType)? {
        switch self {
        case let self as ProtocolDecl:
            return self.protocolSelfType
        case let self as any TypeDecl:
            return self.declaredInterfaceType
        default:
            return nil
        }
    }
}
