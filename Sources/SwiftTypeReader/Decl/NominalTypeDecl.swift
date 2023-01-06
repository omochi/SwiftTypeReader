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
        members.compactMap { $0.asGenericType }
    }

    public var properties: [VarDecl] {
        members.compactMap { $0.asVar }
    }

    public var initializers: [InitDecl] {
        members.compactMap { $0.asInit }
    }

    public var functions: [FuncDecl] {
        members.compactMap { $0.asFunc }
    }

    func findInNominalTypeDecl(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = findInGenericContext(name: name, options: options) {
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

