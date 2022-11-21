import Foundation
import SwiftSyntax
import SwiftSyntaxParser

public struct Reader {
    public var context: Context
    public var module: Module

    public init(
        context: Context,
        module: Module? = nil
    ) {
        self.context = context
        self.module = module ?? context.getOrCreateModule(name: "main")
    }

    public func read(file: URL) throws -> [SourceFile] {
        var sources: [SourceFile] = []

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

    public func read(source: String, file: URL) throws -> SourceFile {
        return try Reader.read(source: source, file: file, on: module)
    }

    static func unescapeIdentifier(_ str: String) -> String {
        return str.trimmingCharacters(in: ["`"])
    }

    static func read(
        source sourceString: String, file: URL,
        on module: Module
    ) throws -> SourceFile {
        let sourceSyntax: SourceFileSyntax = try SyntaxParser.parse(source: sourceString)

        let statements = sourceSyntax.statements.map { $0.item }

        let source = SourceFile(module: module, file: file)

        for decl in statements.compactMap({ $0.as(DeclSyntax.self) }) {
            if let type = readNominalTypeDecl(decl: decl, on: source) {
                source.types.append(type)
            } else if let `import` = readImport(decl: decl, on: source) {
                source.imports.append(`import`)
            }
        }

        module.sources.append(source)

        return source
    }

    static func readMemberDecls(block: MemberDeclBlockSyntax, on context: any DeclContext) -> [any ValueDecl] {
        return block.members.flatMap {
            readMemberDecl(decl: $0.decl, on: context)
        }
    }

    static func readMemberDecl(decl: DeclSyntax, on context: any DeclContext) -> [any ValueDecl] {
        if let type = readNominalTypeDecl(decl: decl, on: context) {
            return [type]
        }
        if let vars = readVars(decl: decl, on: context) {
            return vars
        }
        if let `func` = readFunc(decl: decl, on: context) {
            return [`func`]
        }
        if let cases = readCaseElements(decl: decl, on: context) {
            return cases
        }
        if let associatedType = readAssociatedType(decl: decl, on: context) {
            return [associatedType]
        }

        return []
    }

    static func readNominalTypeDecl(decl: DeclSyntax, on context: any DeclContext) -> (any NominalTypeDecl)? {
        if let decl = decl.as(StructDeclSyntax.self) {
            return readStruct(struct: decl, on: context)
        } else if let decl = decl.as(EnumDeclSyntax.self) {
            return readEnum(enum: decl, on: context)
        } else if let decl = decl.as(ProtocolDeclSyntax.self) {
            return readProtocol(protocol: decl, on: context)
        } else {
            return nil
        }
    }

    static func readStruct(struct structSyntax: StructDeclSyntax, on context: any DeclContext) -> StructDecl? {
        let name = structSyntax.identifier.text

        let `struct` = StructDecl(context: context, name: name)

        `struct`.syntaxGenericParams = readGenericParamList(
            clause: structSyntax.genericParameterClause, on: `struct`
        )

        `struct`.inheritedTypeLocs = readInheritedTypes(
            inheritance: structSyntax.inheritanceClause
        )

        `struct`.members = readMemberDecls(
            block: structSyntax.members, on: `struct`
        )

        return `struct`
    }

    static func readEnum(enum enumSyntax: EnumDeclSyntax, on context: any DeclContext) -> EnumDecl? {
        let name = enumSyntax.identifier.text

        let `enum` = EnumDecl(context: context, name: name)

        `enum`.syntaxGenericParams = readGenericParamList(
            clause: enumSyntax.genericParameters, on: `enum`
        )

        `enum`.inheritedTypeLocs = readInheritedTypes(
            inheritance: enumSyntax.inheritanceClause
        )

        `enum`.members = readMemberDecls(
            block: enumSyntax.members, on: `enum`
        )

        return `enum`
    }

    static func readProtocol(
        `protocol` protocolSyntax: ProtocolDeclSyntax,
        on context: any DeclContext
    ) -> ProtocolDecl? {
        let name = protocolSyntax.identifier.text

        let `protocol` = ProtocolDecl(context: context, name: name)

        `protocol`.inheritedTypeLocs = readInheritedTypes(
            inheritance: protocolSyntax.inheritanceClause
        )

        `protocol`.members = readMemberDecls(block: protocolSyntax.members, on: `protocol`)

        return `protocol`
    }

    static func readCaseElements(
        decl: DeclSyntax,
        on context: any DeclContext
    ) -> [EnumCaseElementDecl]? {
        guard let caseDecl = decl.as(EnumCaseDeclSyntax.self),
              let `enum` = context as? EnumDecl else { return nil }

        return caseDecl.elements.map { (element) in
            readCaseElement(element: element, on: `enum`)
        }
    }

    static func readCaseElement(
        element elementSyntax: EnumCaseElementSyntax,
        on enum: EnumDecl
    ) -> EnumCaseElementDecl {
        let name = elementSyntax.identifier.text
        let element = EnumCaseElementDecl(enum: `enum`, name: name)

        element.associatedValues = Reader.readParamList(
            paramList: elementSyntax.associatedValue?.parameterList,
            on: element
        )

        return element
    }

    static func readAssociatedType(
        decl: DeclSyntax,
        on context: any DeclContext
    ) -> AssociatedTypeDecl? {
        guard let decl = decl.as(AssociatedtypeDeclSyntax.self),
              let `protocol` = context as? ProtocolDecl else { return nil }
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
              let typeRepr = TypeReprReader.read(type: typeSyntax)
        else { return nil }

        return ParamDecl(
            context: context,
            interfaceName: interfaceName,
            name: name,
            typeRepr: typeRepr
        )
    }

    static func readVars(decl: DeclSyntax, on context: any DeclContext) -> [VarDecl]? {
        guard let decl = decl.as(VariableDeclSyntax.self) else { return nil }
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
              let typeRepr = TypeReprReader.read(
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

    static func readFunc(decl: DeclSyntax, on context: any DeclContext) -> FuncDecl? {
        guard let decl = decl.as(FunctionDeclSyntax.self) else { return nil }
        return readFunc(function: decl, on: context)
    }

    static func readFunc(
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
            TypeReprReader.read(type: returnTypeSyntax.returnType)
        }

        return `func`
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
        param.inheritedTypeLocs = TypeReprReader.read(type: paramSyntax.inheritedType)
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
            TypeReprReader.read(type: $0.argumentType)
        }
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
            TypeReprReader.read(type: type.typeName)
                .map { TypeLoc(repr: $0) }
        }
    }

    static func readImport(decl: DeclSyntax, on source: SourceFile) -> ImportDecl? {
        if let decl = decl.as(ImportDeclSyntax.self) {
            return readImport(import: decl, on: source)
        } else {
            return nil
        }
    }

    static func readImport(
        `import` importSyntax: ImportDeclSyntax,
        on source: SourceFile
    ) -> ImportDecl {
        let isScoped = importSyntax.importKind != nil

        let path = importSyntax.path.map { $0.name.text }

        let moduleName: String
        let declName: String?
        if isScoped && path.count >= 2 {
            moduleName = path.dropLast().joined(separator: ".")
            declName = path.last
        } else {
            moduleName = path.joined(separator: ".")
            declName = nil
        }

        return ImportDecl(
            source: source,
            moduleName: moduleName,
            declName: declName
        )
    }
}

