import Foundation
import SwiftSyntax

final class EnumReader {
    private let module: Module
    private let file: URL?

    init(module: Module, file: URL?) {
        self.module = module
        self.file = file
    }

    func read(enumDecl: EnumDeclSyntax) -> EnumType? {
        var caseElements: [CaseElement] = []

        let inheritedTypes: [TypeSpecifier]
        if let clause = enumDecl.inheritanceClause {
            inheritedTypes = Readers.readInheritedTypes(
                module: module, file: file, clause: clause
            )
        } else {
            inheritedTypes = []
        }

        let decls = enumDecl.members.members.map { $0.decl }
        for decl in decls {
            caseElements += readCaseElements(decl: decl)
        }

        return EnumType(
            module: module,
            file: file,
            name: enumDecl.identifier.text,
            inheritedTypes: inheritedTypes,
            caseElements: caseElements
        )
    }

    private func readCaseElements(decl: DeclSyntax) -> [CaseElement] {
        guard let caseDecl = decl.as(EnumCaseDeclSyntax.self) else { return [] }

        return caseDecl.elements.compactMap { (elem) in
            readCaseElement(elem: elem)
        }
    }

    private func readCaseElement(elem: EnumCaseElementSyntax) -> CaseElement? {
        var assocValues: [AssociatedValue] = []

        if let avSyntax = elem.associatedValue {
            assocValues = avSyntax.parameterList.compactMap {
                readAssociatedValue(paramSyntax: $0)
            }

            guard avSyntax.parameterList.count == assocValues.count else {
                return nil
            }
        }

        return CaseElement(
            name: elem.identifier.text,
            associatedValues: assocValues
        )
    }

    private func readAssociatedValue(paramSyntax: FunctionParameterSyntax) -> AssociatedValue? {
        let name: String? = (paramSyntax.firstName?.text).map {
            Readers.unescapeIdentifier($0)
        }

        guard let typeSyntax = paramSyntax.type,
              let typeSpec = Readers.readTypeSpecifier(
                module: module,
                file: file,
                typeSyntax: typeSyntax
              ) else { return nil }

        return AssociatedValue(
            name: name,
            typeSpecifier: typeSpec
        )
    }
}
