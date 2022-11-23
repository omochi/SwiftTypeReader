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

    // MARK: - cast
    public var asEnumCaseElement: EnumCaseElementDecl? { self as? EnumCaseElementDecl }
    public var asEnum: EnumDecl? { self as? EnumDecl }
    public var asFunc: FuncDecl? { self as? FuncDecl }
    public var asGenericContext: (any GenericContext)? { self as? any GenericContext }
    public var asModule: Module? { self as? Module }
    public var asNominalType: (any NominalTypeDecl)? { self as? any NominalTypeDecl }
    public var asProtocol: ProtocolDecl? { self as? ProtocolDecl }
    public var asSourceFile: SourceFile? { self as? SourceFile }
    public var asStruct: StructDecl? { self as? StructDecl }
}
