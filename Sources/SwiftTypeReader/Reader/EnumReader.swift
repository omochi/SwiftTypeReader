import Foundation
import SwiftSyntax

struct EnumReader {
    static func read(enum enumSyntax: EnumDeclSyntax, on context: any DeclContext) -> EnumDecl? {
        let name = enumSyntax.identifier.text

        let `enum` = EnumDecl(context: context, name: name)

        `enum`.syntaxGenericParams = Reader.readGenericParamList(
            clause: enumSyntax.genericParameters, on: `enum`
        )

        `enum`.inheritedTypeLocs = Reader.readInheritedTypes(
            inheritance: enumSyntax.inheritanceClause
        )

        let memberDecls = enumSyntax.members.members.map { $0.decl }

        `enum`.caseElements += memberDecls.flatMap { (memberDecl) in
            readCaseElements(
                decl: memberDecl, on: `enum`
            )
        }

        `enum`.types += memberDecls.compactMap { (memberDecl) in
            Reader.readNominalTypeDecl(
                decl: memberDecl, on: `enum`
            )
        }
        
        return `enum`
    }

    private static func readCaseElements(
        decl: DeclSyntax,
        on enum: EnumDecl
    ) -> [EnumCaseElementDecl] {
        guard let caseDecl = decl.as(EnumCaseDeclSyntax.self) else { return [] }

        return caseDecl.elements.map { (element) in
            readCaseElement(element: element, on: `enum`)
        }
    }

    private static func readCaseElement(
        element elementSyntax: EnumCaseElementSyntax,
        on enum: EnumDecl
    ) -> EnumCaseElementDecl {
        let name = elementSyntax.identifier.text
        let element = EnumCaseElementDecl(enum: `enum`, name: name)

        element.associatedValues = Reader.readParamList(
            paramList: elementSyntax.associatedValue?.parameterList,
            on: element
        )

        return element
    }
}
