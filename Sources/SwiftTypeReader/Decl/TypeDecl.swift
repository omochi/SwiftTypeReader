public protocol TypeDecl: ValueDecl {
    var inheritedTypeLocs: [TypeLoc] { get }
}

extension TypeDecl {
    public var declaredInterfaceType: any SType2 {
        switch interfaceType {
        case let metatype as MetatypeType:
            return metatype.instance
        default:
            return interfaceType
        }
    }
}

extension TypeDecl where Self: DeclContext {
    public var inheritedTypes: [any SType2] {
        inheritedTypeLocs.map { $0.resolve(from: self) }
    }
}
