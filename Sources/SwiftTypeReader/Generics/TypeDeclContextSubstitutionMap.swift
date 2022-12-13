extension TypeDecl {
    // experimental
    public func contextSubstitutionMap(
        parent: (any SType)?,
        genericArgs: [any SType]
    ) throws -> SubstitutionMap {
        var genericArgs = genericArgs

        var dict = SubstitutionMap.Dictionary()

        if let parent {
            dict.merge(parent.contextSubstitutionMap().asDictionary) { $1 }
        }

        var genericParams: [GenericParamType] = []
        if let genericDecl = self.asGenericType {
            genericParams = genericDecl.genericParams.genericParamTypes
        }

        // Unstable logic...
        if let `protocol` = self.asProtocol {
            genericArgs.insert(`protocol`.protocolSelfType, at: 0)
        }

        guard genericParams.count == genericArgs.count else {
            throw MessageError("invalid generic args")
        }

        for pair in zip(genericParams, genericArgs) {
            dict[pair.0] = pair.1
        }

        return SubstitutionMap(
            signature: self.innermostContext.contextGenericSignature,
            dictionary: dict
        )
    }
}
