public struct GenericParamList {
    public init(_ items: [GenericParamDecl] = []) {
        self.items = items
    }

    public var items: [GenericParamDecl]

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if options.type {
            if let param = items.first(where: { $0.name == name }) {
                return param
            }
        }
        return nil
    }

    public func asDeclaredInterfaceTypeArgs() -> [GenericParamType2] {
        items.map { $0.typeDeclaredInterfaceType }
    }
}
