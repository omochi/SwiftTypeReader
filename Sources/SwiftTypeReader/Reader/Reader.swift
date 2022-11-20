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

        for file in fileManager.directoryOrFileEnumerator(at: file) {
            let ext = file.pathExtension
            guard ext == "swift" else {
                continue
            }

            let string = try String(contentsOf: file)
            sources.append(
                try read(source: string, file: file)
            )
        }

        return sources
    }

    public func read(source: String, file: URL) throws -> SourceFileDecl {
        return try Reader.read(source: source, file: file, on: module)
    }

    static func read(
        source sourceString: String, file: URL,
        on module: ModuleDecl
    ) throws -> SourceFileDecl {
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

    static func readNominalTypeDecl(decl: DeclSyntax, on context: any DeclContext) -> (any NominalTypeDecl)? {
        if let decl = decl.as(StructDeclSyntax.self) {
            return StructReader.read(struct: decl, on: context)
        } else if let decl = decl.as(EnumDeclSyntax.self) {
            return EnumReader.read(enum: decl, on: context)
        } else if let decl = decl.as(ProtocolDeclSyntax.self) {
            return ProtocolReader.read(protocol: decl, on: context)
        } else {
            return nil
        }
    }

    static func readImportDecl(decl: DeclSyntax, on source: SourceFileDecl) -> ImportDecl2? {
        if let decl = decl.as(ImportDeclSyntax.self) {
            return ImportReader.read(import: decl, on: source)
        } else {
            return nil
        }
    }

    static func readParamList(
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

        if let first = paramSyntax.firstName {
            if let second = paramSyntax.secondName {
                interfaceName = first.text
                name = second.text
            } else {
                interfaceName = first.text
                name = first.text
            }
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

    static func readVars(decl: DeclSyntax, on context: any DeclContext) -> [VarDecl] {
        guard let decl = decl.as(VariableDeclSyntax.self) else { return [] }
        return readVars(var: decl, on: context)
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

        var modifiers = ModifierReader()
        modifiers.read(decls: varSyntax.modifiers)

        let `var` = VarDecl(
            context: context,
            modifiers: modifiers.modifiers,
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

        var modifiers = ModifierReader()
        modifiers.read(decl: accessorSyntax.modifier)
        modifiers.read(token: accessorSyntax.asyncKeyword)
        modifiers.read(token: accessorSyntax.throwsKeyword)

        return AccessorDecl(var: `var`, modifiers: modifiers.modifiers, kind: kind)
    }

    static func readFunction(decl: DeclSyntax, on context: any DeclContext) -> FuncDecl? {
        guard let decl = decl.as(FunctionDeclSyntax.self) else { return nil }
        return readFunction(function: decl, on: context)
    }

    static func readFunction(
        function functionSyntax: FunctionDeclSyntax,
        on context: any DeclContext
    ) -> FuncDecl? {
        let name = functionSyntax.identifier.text

        var modifiers = ModifierReader()
        modifiers.read(decls: functionSyntax.modifiers)
        modifiers.read(token: functionSyntax.signature.asyncOrReasyncKeyword)
        modifiers.read(token: functionSyntax.signature.throwsOrRethrowsKeyword)

        let `func` = FuncDecl(
            context: context,
            modifiers: modifiers.modifiers,
            name: name
        )

        `func`.parameters = functionSyntax.signature.input.parameterList.compactMap { (param) in
            readParam(param: param, on: `func`)
        }

        `func`.resultTypeRepr = functionSyntax.signature.output.flatMap { (returnTypeSyntax) in
            readTypeRepr(type: returnTypeSyntax.returnType)
        }

        return `func`
    }

    static func readTypeRepr(
        type: TypeSyntax?
    ) -> (any TypeRepr)? {
        guard let type else { return nil }
        return readTypeRepr(type: type)
    }

    static func readTypeRepr(
        type: TypeSyntax
    ) -> (any TypeRepr)? {
        if let member = type.as(MemberTypeIdentifierSyntax.self) {
            guard var repr = readTypeRepr(
                type: member.baseType
            ) as? IdentTypeRepr,
                  let args = readGenericArguments(
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
            guard let args = readGenericArguments(
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

    static func readGenericParamList(
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
                readGenericParam(param: paramSyntax, on: context)
            }
        )
    }

    static func readGenericParam(
        param paramSyntax: GenericParameterSyntax,
        on context: any DeclContext
    ) -> GenericParamDecl {
        let param = GenericParamDecl(
            context: context,
            name: paramSyntax.name.text
        )
        param.inheritedTypeLocs = readTypeRepr(type: paramSyntax.inheritedType)
            .map { TypeLoc(repr: $0) }.toArray()
        return param
    }

    static func readGenericArguments(
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

    static func readInheritedTypes(
        inheritance: TypeInheritanceClauseSyntax?
    ) -> [TypeLoc] {
        guard let inheritance else { return [] }
        return readInheritedTypes(inheritance: inheritance)
    }

    static func readInheritedTypes(
        inheritance: TypeInheritanceClauseSyntax
    ) -> [TypeLoc] {
        return inheritance.inheritedTypeCollection.compactMap { (type) in
            readTypeRepr(type: type.typeName)
                .map { TypeLoc(repr: $0) }
        }
    }
}

