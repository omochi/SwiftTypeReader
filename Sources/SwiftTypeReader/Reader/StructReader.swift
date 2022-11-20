import Foundation
import SwiftSyntax

struct StructReader {
    static func read(struct structSyntax: StructDeclSyntax, on context: any DeclContext) -> StructDecl? {
        let name = structSyntax.identifier.text

        let `struct` = StructDecl(context: context, name: name)

        `struct`.syntaxGenericParams = Reader.readGenericParamList(
            clause: structSyntax.genericParameterClause, on: `struct`
        )

        `struct`.inheritedTypeLocs = Reader.readInheritedTypes(
            inheritance: structSyntax.inheritanceClause
        )

        let memberDecls = structSyntax.members.members.map { $0.decl }

        `struct`.properties = memberDecls.flatMap { (memberDecl) in
            Reader.readVars(decl: memberDecl, on: `struct`)
        }

        `struct`.types = memberDecls.compactMap { (memberDecl) in
            Reader.readNominalTypeDecl(decl: memberDecl, on: `struct`)
        }

        return `struct`
    }
}
