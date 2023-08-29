public protocol TypeDecl: ValueDecl {
    var inheritedTypeReprs: [any TypeRepr] { get }
}

extension TypeDecl {
    public var inheritedTypes: [any SType] {
        func unwrap(repr: any TypeRepr) -> [any TypeRepr] {
            if let tuple = repr.asTuple {
                return tuple.elements.flatMap(unwrap(repr:))
            } else if let composition = repr.asComposition {
                return composition.elements.flatMap(unwrap(repr:))
            } else {
                return [repr]
            }
        }
        return inheritedTypeReprs.flatMap(unwrap(repr:))
            .map { $0.resolve(from: innermostContext) }
    }

    public var declaredInterfaceType: any SType {
        let type = self.interfaceType
        switch type {
        case let metatype as MetatypeType:
            return metatype.instance
        default:
            return type
        }
    }
}
