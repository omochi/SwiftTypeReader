import Foundation
import SwiftSyntax

final class EnumReader {
    private let module: Module
    private let file: URL
    private let location: Location

    init(
        module: Module,
        file: URL,
        location: Location
    ) {
        self.module = module
        self.file = file
        self.location = location
    }

    func read(enumDecl: EnumDeclSyntax) -> EnumType? {
        let name = enumDecl.identifier.text

        let context = Readers.Context(
            module: module,
            file: file,
            location: location.appending(.type(name: name))
        )

        var caseElements: [CaseElement] = []

        let genericParameters: [GenericParameterType]
        if let clause = enumDecl.genericParameters {
            genericParameters = Readers.readGenericParameters(
                context: context,
                clause: clause
            )
        } else {
            genericParameters = []
        }

        let inheritedTypes: [TypeSpecifier]
        if let clause = enumDecl.inheritanceClause {
            inheritedTypes = Readers.readInheritedTypes(
                context: context,
                clause: clause
            )
        } else {
            inheritedTypes = []
        }

        let decls = enumDecl.members.members.map { $0.decl }
        var nestedTypes: [SType] = []
        for decl in decls {
            caseElements += readCaseElements(context: context, decl: decl)
            if let type = Readers.readTypeDeclaration(
                context: context,
                declaration: decl
            ) {
                nestedTypes.append(type)
            }
        }

        return EnumType(
            module: module,
            file: file,
            location: location,
            name: name,
            genericParameters: genericParameters,
            inheritedTypes: inheritedTypes,
            caseElements: caseElements,
            types: nestedTypes
        )
    }

    private func readCaseElements(
        context: Readers.Context,
        decl: DeclSyntax
    ) -> [CaseElement] {
        guard let caseDecl = decl.as(EnumCaseDeclSyntax.self) else { return [] }

        return caseDecl.elements.compactMap { (elem) in
            readCaseElement(context: context, elem: elem)
        }
    }

    private func readCaseElement(
        context: Readers.Context,
        elem: EnumCaseElementSyntax
    ) -> CaseElement? {
        var assocValues: [AssociatedValue] = []

        if let avSyntax = elem.associatedValue {
            assocValues = avSyntax.parameterList.compactMap {
                readAssociatedValue(context: context, paramSyntax: $0)
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

    private func readAssociatedValue(
        context: Readers.Context,
        paramSyntax: FunctionParameterSyntax
    ) -> AssociatedValue? {
        let name: String? = (paramSyntax.firstName?.text).map {
            Readers.unescapeIdentifier($0)
        }

        guard let typeSyntax = paramSyntax.type,
              let typeSpec = Readers.readTypeSpecifier(
                context: context,
                typeSyntax: typeSyntax
              ) else { return nil }

        return AssociatedValue(
            name: name,
            typeSpecifier: typeSpec
        )
    }
}
