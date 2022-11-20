import Foundation
import SwiftSyntax

struct ProtocolReader {
    static func read(
        `protocol` protocolSyntax: ProtocolDeclSyntax,
        on context: any DeclContext
    ) -> ProtocolDecl? {
        let name = protocolSyntax.identifier.text

        let `protocol` = ProtocolDecl(context: context, name: name)

        `protocol`.inheritedTypeLocs = Reader.readInheritedTypes(
            inheritance: protocolSyntax.inheritanceClause
        )

        let memberDecls = protocolSyntax.members.members.map { $0.decl }

        `protocol`.propertyRequirements = memberDecls.flatMap { (memberDecl) in
            Reader.readVars(decl: memberDecl, on: `protocol`)
        }

        `protocol`.functionRequirements = memberDecls.compactMap { (memberDecl) in
            Reader.readFunction(decl: memberDecl, on: `protocol`)
        }

        `protocol`.associatedTypes = memberDecls.compactMap { (memberDecl) in
            readAssociatedType(decl: memberDecl, on: `protocol`)
        }

        return `protocol`
    }

    static func readAssociatedType(
        decl: DeclSyntax,
        on `protocol`: ProtocolDecl
    ) -> AssociatedTypeDecl? {
        guard let decl = decl.as(AssociatedtypeDeclSyntax.self) else { return nil }
        return readAssociatedType(associatedType: decl, on: `protocol`)
    }

    static func readAssociatedType(
        associatedType associatedTypeSyntax: AssociatedtypeDeclSyntax,
        on `protocol`: ProtocolDecl
    ) -> AssociatedTypeDecl {
        let name = associatedTypeSyntax.identifier.text

        let associatedType = AssociatedTypeDecl(protocol: `protocol`, name: name)
        associatedType.inheritedTypeLocs = Reader.readInheritedTypes(
            inheritance: associatedTypeSyntax.inheritanceClause
        )
        return associatedType
    }

    private func readAssociatedType(
        context: Readers.Context,
        decl: DeclSyntax
    ) -> String? {
        guard let assocDecl = decl.as(AssociatedtypeDeclSyntax.self) else { return nil }

        let typeName = assocDecl.identifier.text
        // TODO: inheritanceClause, genericWhereClause are not supported yet.
        return typeName
    }
}
