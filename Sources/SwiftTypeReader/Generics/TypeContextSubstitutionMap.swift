extension SType {
    /*
     Not confident...
     */
    public func contextSubstitutionMap() -> SubstitutionMap {
        do {
            switch self {
            case let type as any NominalType:
                return try type.nominalTypeDecl.contextSubstitutionMap(
                    parent: type.parent,
                    genericArgs: type.genericArgs
                )
            case let type as TypeAliasType:
                return try type.decl.contextSubstitutionMap(
                    parent: type.parent,
                    genericArgs: type.genericArgs
                )
            default:
                throw MessageError("unsupported type: \(self)")
            }
        } catch {
            fatalError("\(error)")
        }
    }
}
