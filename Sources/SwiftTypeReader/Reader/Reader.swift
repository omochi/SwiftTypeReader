import Foundation
import SwiftSyntax
import SwiftSyntaxParser

public struct Reader {
    public var context: Context
    public var module: ModuleDecl

    public init(
        context: Context,
        module: ModuleDecl? = nil
    ) {
        self.context = context
        self.module = module ?? context.getOrCreateModule(name: "main")
    }

    public func read(file: URL) throws -> [SourceFileDecl] {
        var sources: [SourceFileDecl] = []

        for file in fm.directoryOrFileEnumerator(at: file) {
            let ext = file.pathExtension
            guard ext == "swift" else {
                continue
            }

            let string = try String(contentsOf: file)
            sources.append(
                try readImpl(source: string, file: file)
            )
        }

        return sources
    }

    public func read(source: String, file: URL) throws -> SourceFileDecl {
        return try readImpl(source: source, file: file)
    }

    private func readImpl(source sourceString: String, file: URL) throws -> SourceFileDecl {
        let sourceSyntax: SourceFileSyntax = try SyntaxParser.parse(source: sourceString)

        let statements = sourceSyntax.statements.map { $0.item }

        let source = SourceFileDecl(module: module, file: file)

        for decl in statements.compactMap({ $0.as(DeclSyntax.self) }) {
            if let type = readNominalTypeDecl(decl: decl, on: source) {
                source.types.append(type)
            } else if let `import` = readImportDecl(decl: decl, on: source) {
                source.imports.append(`import`)
            }
        }

        module.sources.append(source)

        return source
    }

    func readNominalTypeDecl(decl: DeclSyntax, on context: any DeclContext) -> (any NominalTypeDecl)? {
        if let decl = decl.as(StructDeclSyntax.self) {
            let reader = StructReader(reader: self)
            return reader.read(struct: decl, on: context)
        } else if let decl = decl.as(EnumDeclSyntax.self) {
            let reader = EnumReader(reader: self)
            return reader.read(enum: decl, on: context)
        } else if let decl = decl.as(ProtocolDeclSyntax.self) {
            let reader = ProtocolReader(reader: self)
            return reader.read(protocol: decl, on: context)
        } else {
            return nil
        }
    }

    func readImportDecl(decl: DeclSyntax, on source: SourceFileDecl) -> ImportDecl2? {
        if let decl = decl.as(ImportDeclSyntax.self) {
            let reader = ImportReader(reader: self)
            return reader.read(import: decl, on: source)
        } else {
            return nil
        }
    }

    static func readOptionalParamList(
        paramList: FunctionParameterListSyntax?,
        on context: any DeclContext
    ) -> [ParamDecl] {
        guard let paramList else { return [] }
        return readParamList(paramList: paramList, on: context)
    }

    static func readParamList(
        paramList paramListSyntax: FunctionParameterListSyntax,
        on context: any DeclContext
    ) -> [ParamDecl] {
        return paramListSyntax.compactMap { (paramSyntax) in
            readParam(param: paramSyntax, on: context)
        }
    }

    static func readParam(
        param paramSyntax: FunctionParameterSyntax,
        on context: any DeclContext
    ) -> ParamDecl? {
        var interfaceName: String? = nil
        var name: String? = nil

        if let token = paramSyntax.firstName {
            name = token.text
        }
        if let token = paramSyntax.secondName {
            interfaceName = name
            name = token.text
        }

        guard let typeSyntax = paramSyntax.type,
              let typeRepr = Reader.readTypeRepr(type: typeSyntax)
        else { return nil }

        return ParamDecl(
            context: context,
            interfaceName: interfaceName,
            name: name,
            typeRepr: typeRepr
        )
    }

    static func readVars(
        `var`: VariableDeclSyntax,
        on context: any DeclContext
    ) -> [VarDecl] {
        return `var`.bindings.compactMap { (binding) in
            readVar(var: `var`, binding: binding, on: context)
        }
    }

    static func readVar(
        `var` varSyntax: VariableDeclSyntax,
        binding: PatternBindingSyntax,
        on context: any DeclContext
    ) -> VarDecl? {
        guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        guard let kind = VarKind(rawValue: varSyntax.letOrVarKeyword.text) else {
            return nil
        }

        let name = Reader.unescapeIdentifier(ident.identifier.text)

        guard let typeAnno = binding.typeAnnotation,
              let typeRepr = Reader.readTypeRepr(
                type: typeAnno.type
              ) else
        {
            return nil
        }

        var modifiers: [DeclModifier] = []

        if let modifiersSyntax = varSyntax.modifiers {
            for modifierSyntax in modifiersSyntax {
                if let modifier = DeclModifier(rawValue: modifierSyntax.name.text) {
                    modifiers.append(modifier)
                }
            }
        }

        let `var` = VarDecl(
            context: context,
            modifiers: modifiers,
            kind: kind,
            name: name,
            typeRepr: typeRepr
        )

        if let accessor = binding.accessor {
            `var`.accessors += readVarAccessor(accessor: accessor, on: `var`)
        }

        return `var`
    }

    static func readVarAccessor(
        accessor: Syntax,
        on `var`: VarDecl
    ) -> [AccessorDecl] {
        if accessor.is(CodeBlockSyntax.self) {
            let accessor = AccessorDecl(var: `var`, modifiers: [], kind: .get)
            return [accessor]
        } else if let accessorsSyntax = accessor.as(AccessorBlockSyntax.self) {
            return accessorsSyntax.accessors.compactMap {
                readAccessor(accessor: $0, on: `var`)
            }
        } else {
            return []
        }
    }

    static func readAccessor(
        accessor accessorSyntax: AccessorDeclSyntax,
        on `var`: VarDecl
    ) -> AccessorDecl? {
        guard let kind = AccessorKind(rawValue: accessorSyntax.accessorKind.text) else {
            return nil
        }

        var modifiers: [DeclModifier] = []

        if let modifierSyntax = accessorSyntax.modifier {
            if let modifier = DeclModifier(rawValue: modifierSyntax.name.text) {
                modifiers.append(modifier)
            }
        }

        if let asyncSyntax = accessorSyntax.asyncKeyword {
            if let modifier = DeclModifier(rawValue: asyncSyntax.text) {
                modifiers.append(modifier)
            }
        }

        if let throwsSyntax = accessorSyntax.throwsKeyword {
            if let modifier = DeclModifier(rawValue: throwsSyntax.text) {
                modifiers.append(modifier)
            }
        }

        return AccessorDecl(var: `var`, modifiers: modifiers, kind: kind)
    }

    static func readTypeRepr(
        type: TypeSyntax
    ) -> (any TypeRepr)? {
        if let member = type.as(MemberTypeIdentifierSyntax.self) {
            guard var repr = readTypeRepr(
                type: member.baseType
            ) as? IdentTypeRepr,
                  let args = readOptionalGenericArguments(
                    clause: member.genericArgumentClause
                  )
            else { return nil }

            repr.elements.append(
                .init(
                    name: member.name.text,
                    genericArgs: args
                )
            )

            return repr
        }

        if let simple = type.as(SimpleTypeIdentifierSyntax.self) {
            guard let args = readOptionalGenericArguments(
                clause: simple.genericArgumentClause
            ) else { return nil }

            return IdentTypeRepr([
                .init(
                    name: simple.name.text,
                    genericArgs: args
                )
            ])
        }

        if let optional = type.as(OptionalTypeSyntax.self) {
            guard let wrapped = readTypeRepr(
                type: optional.wrappedType
            ) else { return nil }

            return IdentTypeRepr([
                .init(
                    name: "Optional",
                    genericArgs: [wrapped]
                )
            ])
        } else if let array = type.as(ArrayTypeSyntax.self) {
            guard let element = readTypeRepr(
                type: array.elementType
            ) else { return nil }

            return IdentTypeRepr([
                .init(
                    name: "Array",
                    genericArgs: [element]
                )
            ])
        } else if let dictionary = type.as(DictionaryTypeSyntax.self) {
            guard let key = readTypeRepr(
                type: dictionary.keyType
            ),
                  let value = readTypeRepr(
                    type: dictionary.valueType
                  ) else { return nil }

            return IdentTypeRepr([
                .init(
                    name: "Dictionary",
                    genericArgs: [key, value]
                )
            ])
        } else {
            return nil
        }
    }

    static func readOptionalGenericParamList(
        clause: GenericParameterClauseSyntax?,
        on context: any DeclContext
    ) -> GenericParamList {
        guard let clause else {
            return GenericParamList([])
        }
        return readGenericParamList(clause: clause, on: context)
    }

    static func readGenericParamList(
        clause: GenericParameterClauseSyntax,
        on context: any DeclContext
    ) -> GenericParamList {
        return GenericParamList(
            clause.genericParameterList.map { (paramSyntax) in
                return GenericParamDecl(
                    context: context,
                    name: paramSyntax.name.text
                )
            }
        )
    }

    static func readOptionalGenericArguments(
        clause: GenericArgumentClauseSyntax?
    ) -> [any TypeRepr]? {
        guard let clause else { return [] }
        return readGenericArguments(clause: clause)
    }

    static func readGenericArguments(
        clause: GenericArgumentClauseSyntax
    ) -> [any TypeRepr]? {
        return clause.arguments.compactMap {
            readTypeRepr(type: $0.argumentType)
        }
    }

    static func unescapeIdentifier(_ str: String) -> String {
        return str.trimmingCharacters(in: ["`"])
    }

    static func readOptionalInheritedTypes(
        inheritance: TypeInheritanceClauseSyntax?
    ) -> [any TypeRepr] {
        guard let inheritance else { return [] }
        return readInheritedTypes(inheritance: inheritance)
    }

    static func readInheritedTypes(
        inheritance: TypeInheritanceClauseSyntax
    ) -> [any TypeRepr] {
        return inheritance.inheritedTypeCollection.compactMap { (type) in
            readTypeRepr(type: type.typeName)
        }
    }
}

