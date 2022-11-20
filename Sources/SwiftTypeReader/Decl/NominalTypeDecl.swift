public protocol NominalTypeDecl: GenericTypeDecl {
    var name: String { get }
    var types: [any GenericTypeDecl] { get }

    func makeNominalDeclaredInterfaceType(
        parent: (any SType2)?,
        genericArgs: [any SType2]
    ) -> any NominalType
}

extension NominalTypeDecl {
    public var valueName: String? { name }

    func findInNominalTypeDecl(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = genericParams.find(name: name, options: options) {
            return decl
        }
        if options.type {
            if let decl = types.first(where: { $0.valueName == name }) {
                return decl
            }
        }
        return nil
    }
}

