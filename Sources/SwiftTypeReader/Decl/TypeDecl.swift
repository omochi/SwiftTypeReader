public protocol TypeDecl: ValueDecl {
    var inheritedTypeLocs: [TypeLoc] { get }
}

extension TypeDecl {
    public var inheritedTypes: [any SType] {
        inheritedTypeLocs.map { $0.resolve(from: innermostContext) }
    }

    public var declaredInterfaceType: any SType {
        switch interfaceType {
        case let metatype as MetatypeType:
            return metatype.instance
        default:
            return interfaceType
        }
    }
}
