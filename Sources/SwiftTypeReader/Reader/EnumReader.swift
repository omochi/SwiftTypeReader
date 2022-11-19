import Foundation
import SwiftSyntax

struct EnumReader {
    var reader: Reader

    init(
        reader: Reader
    ) {
        self.reader = reader
    }

    func read(enum enumSyntax: EnumDeclSyntax, on context: any DeclContext) -> EnumDecl? {
        let name = enumSyntax.identifier.text

        let `enum` = EnumDecl(context: context, name: name)

        `enum`.genericParams = Reader.readOptionalGenericParamList(
            clause: enumSyntax.genericParameters, on: `enum`
        )

        `enum`.inheritedTypeReprs = Reader.readOptionalInheritedTypes(
            inheritance: enumSyntax.inheritanceClause
        )

        let memberDecls = enumSyntax.members.members.map { $0.decl }
        for memberDecl in memberDecls {
            `enum`.caseElements += readCaseElements(
                decl: memberDecl, on: `enum`
            )

            if let nestedType = reader.readNominalTypeDecl(
                decl: memberDecl, on: `enum`
            ) {
                `enum`.types.append(nestedType)
            }
        }

        return `enum`
    }

    private func readCaseElements(
        decl: DeclSyntax,
        on enum: EnumDecl
    ) -> [EnumCaseElementDecl] {
        guard let caseDecl = decl.as(EnumCaseDeclSyntax.self) else { return [] }

        return caseDecl.elements.map { (element) in
            readCaseElement(element: element, on: `enum`)
        }
    }

    private func readCaseElement(
        element elementSyntax: EnumCaseElementSyntax,
        on enum: EnumDecl
    ) -> EnumCaseElementDecl {
        let name = elementSyntax.identifier.text
        let element = EnumCaseElementDecl(enum: `enum`, name: name)

        element.associatedValues = Reader.readOptionalParamList(
            paramList: elementSyntax.associatedValue?.parameterList,
            on: element
        )

        return element
    }
}
