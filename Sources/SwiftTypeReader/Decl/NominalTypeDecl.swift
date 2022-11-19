public protocol NominalTypeDecl: GenericTypeDecl {
    var name: String { get }
    var inheritedTypeReprs: [any TypeRepr] { get }
    var types: [any GenericTypeDecl] { get }
}

extension NominalTypeDecl {
    public var valueName: String? { name }

    public var inheritedTypes: [any SType2] {
        inheritedTypeReprs.map { $0.resolve(from: self) }
    }

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

