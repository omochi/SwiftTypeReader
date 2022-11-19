struct DeclaredInterfaceTypeRequest: Request {
    @AnyDeclStorage var decl: any Decl

    func evaluate(on evaluator: RequestEvaluator) throws -> any SType2 {
        switch decl {
        case let decl as any NominalTypeDecl:
            var parent: (any SType2)? = nil
            if let parentDecl = decl.parentContext as? any TypeDecl {
                parent = parentDecl.declaredInterfaceType
            }

            let genericArgs = decl.genericParams.asDeclaredInterfaceTypeArgs()
            switch decl {
            case let decl as StructDecl:
                return StructType2(
                    decl: decl,
                    parent: parent,
                    genericArgs: genericArgs
                )
            case let decl as EnumDecl:
                return EnumType2(
                    decl: decl,
                    parent: parent,
                    genericArgs: genericArgs
                )
            case let decl as ProtocolDecl:
                return ProtocolType2(
                    decl: decl
                )
            default: break
            }
        case let decl as GenericParamDecl:
            return decl.typedDeclaredInterfaceType
        default: break
        }
        throw MessageError("invalid decl: \(decl)")
    }
}
