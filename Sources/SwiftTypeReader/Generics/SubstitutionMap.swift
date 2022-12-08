public struct SubstitutionMap: Hashable & CustomStringConvertible {
    public init(
        signature: GenericSignature = GenericSignature(),
        replacementTypes: [any SType] = []
    ) {
        self.signature = signature
        self.replacementTypes = replacementTypes

        precondition(signature.params.count == replacementTypes.count)
    }

    public var signature: GenericSignature
    @AnyTypeArrayStorage public var replacementTypes: [any SType]

    public func replacementType(for param: GenericParamType) -> (any SType)? {
        guard let index = signature.params.firstIndex(of: param) else { return nil }
        return replacementTypes[index]
    }

    public var description: String {
        var pairs: [String] = []
        for (param, rep) in zip(signature.params, replacementTypes) {
            pairs.append(param.description + ": " + rep.description)
        }
        return "[" + pairs.joined(separator: ", ") + "]"
    }
}
