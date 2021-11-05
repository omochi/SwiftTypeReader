import Foundation
import SwiftSyntax

final class ProtocolReader {
    private let module: Module
    private let file: URL?
    private let location: Location

    init(
        module: Module,
        file: URL?,
        location: Location
    ) {
        self.module = module
        self.file = file
        self.location = location
    }

    func read(protocolDecl: ProtocolDeclSyntax) -> ProtocolType? {
        let name = protocolDecl.identifier.text

        let context = Readers.Context(
            module: module,
            file: file,
            location: location.appending(.type(name: name))
        )

        var caseElements: [CaseElement] = []

        let inheritedTypes: [TypeSpecifier]
        if let clause = protocolDecl.inheritanceClause {
            inheritedTypes = Readers.readInheritedTypes(
                context: context,
                clause: clause
            )
        } else {
            inheritedTypes = []
        }

        var propertyRequirements: [PropertyRequirement] = []
        let decls = protocolDecl.members.members.map { $0.decl }
        for decl in decls {
            print(decl, decl.syntaxNodeType)
            propertyRequirements += readStoredProperties(
                context: context,
                decl: decl
            )
        }

        return ProtocolType(
            module: module,
            file: file,
            location: location,
            name: name,
            inheritedTypes: inheritedTypes,
            propertyRequirements: propertyRequirements
        )
    }

    private func readStoredProperties(
        context: Readers.Context,
        decl: DeclSyntax
    ) -> [PropertyRequirement] {
        if let varDecl = decl.as(VariableDeclSyntax.self) {

            let isStatic = varDecl.modifiers?.contains(where: { $0.name.text == "static" }) ?? false
            return varDecl.bindings.compactMap {
                readPropertyRequirement(context: context, binding: $0, isStatic: isStatic)
            }
        } else {
            return []
        }
    }

    private func readPropertyRequirement(
        context: Readers.Context,
        binding: PatternBindingSyntax,
        isStatic: Bool
    ) -> PropertyRequirement? {
        guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        let name = Readers.unescapeIdentifier(ident.identifier.text)

        guard let typeAnno = binding.typeAnnotation,
              let typeSpec = Readers.readTypeSpecifier(
                context: context,
                typeSyntax: typeAnno.type
              ) else
        {
            return nil
        }

        guard let rawAccessors = binding.accessor?.as(AccessorBlockSyntax.self)?.accessors else {
            return nil
        }

        let accessors = rawAccessors.compactMap { accessor -> PropertyRequirement.Accessor? in
            switch accessor.accessorKind.text {
            case "get":
                return .get(
                    mutating: accessor.modifier?.name.text == "mutating",
                    async: accessor.asyncKeyword != nil,
                    throws: accessor.throwsKeyword != nil
                )
            case "set":
                return .set(nonmutating: accessor.modifier?.name.text == "nonmutating")
            default:
                return nil
            }
        }

        return PropertyRequirement(
            name: name,
            typeSpecifier: typeSpec,
            accessors: accessors,
            isStatic: isStatic
        )
    }

}
