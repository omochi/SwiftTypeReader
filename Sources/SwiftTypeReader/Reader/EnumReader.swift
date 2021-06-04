import SwiftSyntax

final class EnumReader {
    private let module: Module

    init(module: Module) {
        self.module = module
    }

    func read(enumDecl: EnumDeclSyntax) -> EnumType? {
        var caseElements: [CaseElement] = []

        let decls = enumDecl.members.members.map { $0.decl }
        for decl in decls {
            caseElements += readCaseElements(decl: decl)
        }

        return EnumType(
            name: enumDecl.identifier.text,
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
              let typeSpec = Readers.readTypeSpecifier(typeSyntax) else { return nil }

        return AssociatedValue(
            name: name,
            unresolvedType: UnresolvedType(
                module: module,
                specifier: typeSpec
            )
        )
    }
}
