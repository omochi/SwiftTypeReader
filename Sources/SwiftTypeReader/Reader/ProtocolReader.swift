import Foundation
import SwiftSyntax

struct ProtocolReader {
    func read(
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
//
//        let associatedTypes = memberDecls.compactMap { decl in
//            readAssociatedType(context: context, decl: decl)
//        }

        return `protocol`
    }

    private func readFunctionRequirement(
        context: Readers.Context,
        decl: DeclSyntax
    ) -> FunctionRequirement? {
        guard let funDecl = decl.as(FunctionDeclSyntax.self) else { return nil }

        let name = funDecl.identifier.text
        let isStatic = funDecl.modifiers?.contains(where: { $0.name.text == "static" }) ?? false

        let inputParams = funDecl.signature.input.parameterList.compactMap { param -> FunctionRequirement.Parameter? in
            guard let typeSyntax = param.type,
                  let type = Readers.readTypeSpecifier(context: context, typeSyntax: typeSyntax),
                    let firstName = param.firstName?.text
            else { return nil }

            let secondName = param.secondName?.text
            return FunctionRequirement.Parameter(
                label: secondName == nil ? nil : firstName,
                name: secondName == nil ? firstName : secondName.unsafelyUnwrapped,
                type: type
            )
        }

        let outputType: TypeSpecifier?
        if let output = funDecl.signature.output {
            outputType = Readers.readTypeSpecifier(context: context, typeSyntax: output.returnType)
        } else {
            outputType = nil
        }

        return .init(
            name: name,
            parameters: inputParams,
            outputType: outputType,
            isStatic: isStatic,
            isThrows: funDecl.signature.throwsOrRethrowsKeyword?.text == "throws",
            isRethrows: funDecl.signature.throwsOrRethrowsKeyword?.text == "rethrows",
            isAsync: funDecl.signature.asyncOrReasyncKeyword?.text == "async",
            isReasync: funDecl.signature.asyncOrReasyncKeyword?.text == "reasync"
        )
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
