public protocol TypeDecl: ValueDecl {
    var inheritedTypeReprs: [any TypeRepr] { get }
}

extension TypeDecl {
    public var inheritedTypes: [any SType] {
        inheritedTypeReprs.map { $0.resolve(from: innermostContext) }
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
