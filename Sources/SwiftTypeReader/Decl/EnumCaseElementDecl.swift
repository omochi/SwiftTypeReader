public final class EnumCaseElementDecl: ValueDecl & DeclContext {
    public enum LiteralExpr: Equatable {
        case string(_ value: String)
        case integer(_ value: Int)
    }

    public init(`enum`: EnumDecl, name: String, rawValue: LiteralExpr?) {
        self.enum = `enum`
        self.name = name
        self.associatedValues = []
        self.rawValue = rawValue
    }

    public unowned var `enum`: EnumDecl
    public var parentContext: (any DeclContext)? { `enum` }

    public var name: String
    public var valueName: String? { name }
    public var associatedValues: [CaseParamDecl]
    public var rawValue: LiteralExpr?

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if options.value {
            if let decl = associatedValues.first(where: { $0.name == name }) {
                return decl
            }
        }

        return nil
    }
}
