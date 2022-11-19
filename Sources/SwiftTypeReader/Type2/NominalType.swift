public protocol NominalType: SType2 {
    var nominalTypeDecl: any NominalTypeDecl { get }
    var parent: (any SType2)? { get }
    var genericArgs: [any SType2] { get set }
}

extension NominalType {
    public var name: String {
        nominalTypeDecl.name
    }

    public var description: String {
        var s = ""

        if let parent {
            s += parent.description
        }

        if !s.isEmpty {
            s += "."
        }

        s += name
        s += Printer.genericClause(genericArgs.map { $0.description })

        return s
    }
}
