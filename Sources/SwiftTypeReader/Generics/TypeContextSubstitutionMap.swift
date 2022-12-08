extension SType {
    /*
     Not confident...
     */
    public func contextSubstitutionMap() -> SubstitutionMap {
        guard let context = self.typeContext() else {
            return SubstitutionMap()
        }

        let signature = context.contextGenericSignature
        var table: [GenericParamType: any SType] = [:]

        var typeIter: any SType = self
        while true {
            guard let type = typeIter.asNominal else {
                break
            }

            for (index, param) in type.nominalTypeDecl.genericParams.items.enumerated() {
                table[param.typedDeclaredInterfaceType] = type.genericArgs[index]
            }

            guard let parent = type.parent else {
                break
            }
            typeIter = parent
        }

        let repls: [any SType] = signature.params.map { table[$0]! }

        return SubstitutionMap(
            signature: signature,
            replacementTypes: repls
        )
    }

    private func typeContext() -> (any DeclContext)? {
        switch self {
        case let t as any NominalType: return t.nominalTypeDecl
        default: return nil
        }
    }
}
