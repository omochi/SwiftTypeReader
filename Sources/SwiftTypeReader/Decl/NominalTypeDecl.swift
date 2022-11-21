public protocol NominalTypeDecl: GenericTypeDecl {
    var name: String { get }
    var members: [any ValueDecl] { get }

    func makeNominalDeclaredInterfaceType(
        parent: (any SType)?,
        genericArgs: [any SType]
    ) -> any NominalType
}

extension NominalTypeDecl {
    public var valueName: String? { name }

    public var types: [any GenericTypeDecl] {
        members.compactMap { $0 as? any GenericTypeDecl }
    }

    public var properties: [VarDecl] {
        members.compactMap { $0 as? VarDecl }
    }

    public var functions: [FuncDecl] {
        members.compactMap { $0 as? FuncDecl }
    }

    func findInNominalTypeDecl(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = genericParams.find(name: name, options: options) {
            return decl
        }

        if let decl = members.first(where: { (member) in
            guard member.valueName == name else { return false }

            if member is any TypeDecl {
                if options.type {
                    return true
                }
            } else {
                if options.value {
                    return true
                }
            }

            return false
        }) {
            return decl
        }

        return nil
    }
}

