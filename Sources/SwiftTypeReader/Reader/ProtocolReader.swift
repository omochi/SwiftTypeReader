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
            propertyRequirements += readStoredProperties(
                context: context,
                decl: decl
            )
        }

        var functionRequirements: [FunctionRequirement] = []
        for decl in decls {
            if let functionRequirement = readFunctionRequirement(
                context: context,
                decl: decl
            ) {
                functionRequirements.append(functionRequirement)
            }
        }

        return ProtocolType(
            module: module,
            file: file,
            location: location,
            name: name,
            inheritedTypes: inheritedTypes,
            propertyRequirements: propertyRequirements,
            functionRequirements: functionRequirements
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

    private func readFunctionRequirement(
        context: Readers.Context,
        decl: DeclSyntax
    ) -> FunctionRequirement? {
        guard let funDecl = decl.as(FunctionDeclSyntax.self) else { return nil }

        let name = funDecl.identifier.text
        let isStatic = funDecl.modifiers?.contains(where: { $0.name.text == "static" }) ?? false

        let inputParams = funDecl.signature.input.parameterList.compactMap { param -> FunctionRequirement.InputParameter? in
            guard let typeSyntax = param.type,
                  let type = Readers.readTypeSpecifier(context: context, typeSyntax: typeSyntax),
                    let firstName = param.firstName?.text
            else { return nil }

            let secondName = param.secondName?.text
            return FunctionRequirement.InputParameter(
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
            inputParameters: inputParams,
            outputType: outputType,
            isStatic: isStatic,
            isThrows: funDecl.signature.throwsOrRethrowsKeyword?.text == "throws",
            isRethrows: funDecl.signature.throwsOrRethrowsKeyword?.text == "rethrows",
            isAsync: funDecl.signature.asyncOrReasyncKeyword?.text == "async",
            isReasync: funDecl.signature.asyncOrReasyncKeyword?.text == "reasync"
        )
    }
}
