import Foundation
import SwiftSyntax

struct StructReader {
    var reader: Reader

    init(reader: Reader) {
        self.reader = reader
    }

    func read(struct structSyntax: StructDeclSyntax, on context: any DeclContext) -> StructDecl? {
        let name = structSyntax.identifier.text

        let `struct` = StructDecl(context: context, name: name)

        `struct`.genericParams = Reader.readOptionalGenericParamList(
            clause: structSyntax.genericParameterClause, on: `struct`
        )

        `struct`.inheritedTypeReprs = Reader.readOptionalInheritedTypes(
            inheritance: structSyntax.inheritanceClause
        )

        let memberDecls = structSyntax.members.members.map { $0.decl }

        `struct`.properties = memberDecls.flatMap { (memberDecl) in
            readProperties(decl: memberDecl, on: `struct`)
        }

        `struct`.types = memberDecls.compactMap { (memberDecl) in
            reader.readNominalTypeDecl(decl: memberDecl, on: `struct`)
        }

        return `struct`
    }

    private func readProperties(
        decl: DeclSyntax,
        on `struct`: StructDecl
    ) -> [VarDecl] {
        guard let varDecl = decl.as(VariableDeclSyntax.self) else { return [] }
        return Reader.readVars(var: varDecl, on: `struct`)
    }
}
