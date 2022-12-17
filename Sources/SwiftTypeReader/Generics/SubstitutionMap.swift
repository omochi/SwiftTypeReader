public struct SubstitutionMap: Hashable & CustomStringConvertible {
    public typealias Dictionary = [GenericParamType: any SType]

    public typealias Pair = (param: GenericParamType, replacement: any SType)

    public init(
        signature: GenericSignature = GenericSignature(),
        replacementTypes: [any SType] = []
    ) {
        self.signature = signature
        self.replacementTypes = replacementTypes

        precondition(signature.params.count == replacementTypes.count)
    }

    public init(
        signature: GenericSignature,
        dictionary: Dictionary
    ) {
        let repls = signature.params.map { dictionary[$0]! }
        self.init(signature: signature, replacementTypes: repls)
    }

    public var signature: GenericSignature
    @AnyTypeArrayStorage public var replacementTypes: [any SType]

    public func replacementType(for param: GenericParamType) -> (any SType)? {
        guard let index = signature.params.firstIndex(of: param) else { return nil }
        return replacementTypes[index]
    }

    public var pairs: [Pair] {
        zip(signature.params, replacementTypes).map { Pair(param: $0, replacement: $1) }
    }

    public var asDictionary: Dictionary {
        var dict = Dictionary()
        for pair in pairs {
            dict[pair.param] = pair.replacement
        }
        return dict
    }

    public var description: String {
        var strs: [String] = []
        for (param, repl) in pairs {
            strs.append(param.description + ": " + repl.description)
        }
        return "[" + strs.joined(separator: ", ") + "]"
    }
}
