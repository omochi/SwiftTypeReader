import Foundation
import SwiftSyntax
import SwiftParser

public struct Reader {
    public var context: Context
#if !os(WASI)
    public var fileManager: FileManager
#endif
    public var module: Module

#if !os(WASI)
    public init(
        context: Context,
        fileManager: FileManager = .default,
        module: Module? = nil
    ) {
        self.context = context
        self.fileManager = fileManager
        self.module = module ?? context.getOrCreateModule(name: "main")
    }
#else
    public init(
        context: Context,
        module: Module? = nil
    ) {
        self.context = context
        self.module = module ?? context.getOrCreateModule(name: "main")
    }
#endif

#if !os(WASI)
    public func read(directory: URL) throws -> [SourceFile] {
        var sources: [SourceFile] = []

        for file in fileManager.enumerateRelative(path: directory, options: [.skipsHiddenFiles]) {
            let ext = file.pathExtension
            guard ext == "swift" else {
                continue
            }

            let string = try String(contentsOf: file)
            sources.append(
                read(source: string, file: file)
            )
        }

        return sources
    }
#endif

    public func read(source: String, file: URL) -> SourceFile {
        return Reader.read(source: source, file: file, on: module)
    }

    static func unescapeIdentifier(_ str: String) -> String {
        return str.trimmingCharacters(in: ["`"])
    }

    static func read(
        source sourceString: String, file: URL,
        on module: Module
    ) -> SourceFile {
        let sourceSyntax: SourceFileSyntax = Parser.parse(source: sourceString)

        let statements = sourceSyntax.statements.map { $0.item }

        let source = SourceFile(module: module, file: file)

        for decl in statements.compactMap({ $0.as(DeclSyntax.self) }) {
            if let type = readNominalType(decl: decl, on: source) {
                source.types.append(type)
            } else if let type = readTypeAlias(decl: decl, on: source) {
                source.types.append(type)
            } else if let `import` = readImport(decl: decl, on: source) {
                source.imports.append(`import`)
            } else if let `func` = readFunc(decl: decl, on: source) {
                source.funcs.append(`func`)
            }
        }

        module.sources.append(source)

        return source
    }

    static func readMembers(block: MemberBlockSyntax, on context: some DeclContext) -> [any ValueDecl] {
        return block.members.flatMap {
            readMember(decl: $0.decl, on: context)
        }
    }

    static func readMember(decl: DeclSyntax, on context: some DeclContext) -> [any ValueDecl] {
        if let type = readNominalType(decl: decl, on: context) {
            return [type]
        } else if let type = readTypeAlias(decl: decl, on: context) {
            return [type]
        } else if let vars = readVars(decl: decl, on: context) {
            return vars
        } else if let `func` = readFunc(decl: decl, on: context) {
            return [`func`]
        } else if let `init` = readInit(decl: decl, on: context) {
            return [`init`]
        } else if let cases = readCaseElements(decl: decl, on: context) {
            return cases
        } else if let associatedType = readAssociatedType(decl: decl, on: context) {
            return [associatedType]
        } else {
            return []
        }
    }

    static func readNominalType(decl: DeclSyntax, on context: some DeclContext) -> (any NominalTypeDecl)? {
        if let decl = decl.as(StructDeclSyntax.self) {
            return readStruct(struct: decl, on: context)
        } else if let decl = decl.as(EnumDeclSyntax.self) {
            return readEnum(enum: decl, on: context)
        } else if let decl = decl.as(ProtocolDeclSyntax.self) {
            return readProtocol(protocol: decl, on: context)
        } else if let decl = decl.as(ClassDeclSyntax.self) {
            return readClass(class: decl, on: context)
        } else {
            return nil
        }
    }

    static func readStruct(struct structSyntax: StructDeclSyntax, on context: some DeclContext) -> StructDecl? {
        let name = structSyntax.name.text

        let `struct` = StructDecl(context: context, name: name)

        `struct`.comment = structSyntax.leadingTrivia.description

        `struct`.modifiers = readModifires(decls: structSyntax.modifiers)
        
        `struct`.syntaxGenericParams = readGenericParamList(
            clause: structSyntax.genericParameterClause, on: `struct`
        )

        `struct`.inheritedTypeReprs = readInheritedTypes(
            inheritance: structSyntax.inheritanceClause
        )

        `struct`.members = readMembers(
            block: structSyntax.memberBlock, on: `struct`
        )

        return `struct`
    }

    static func readEnum(enum enumSyntax: EnumDeclSyntax, on context: some DeclContext) -> EnumDecl? {
        let name = enumSyntax.name.text

        let `enum` = EnumDecl(context: context, name: name)

        `enum`.modifiers = readModifires(decls: enumSyntax.modifiers)

        `enum`.syntaxGenericParams = readGenericParamList(
            clause: enumSyntax.genericParameterClause, on: `enum`
        )

        `enum`.inheritedTypeReprs = readInheritedTypes(
            inheritance: enumSyntax.inheritanceClause
        )

        `enum`.members = readMembers(
            block: enumSyntax.memberBlock, on: `enum`
        )

        return `enum`
    }

    static func readProtocol(
        `protocol` protocolSyntax: ProtocolDeclSyntax,
        on context: some DeclContext
    ) -> ProtocolDecl? {
        let name = protocolSyntax.name.text

        let `protocol` = ProtocolDecl(context: context, name: name)

        `protocol`.modifiers = readModifires(decls: protocolSyntax.modifiers)

        `protocol`.inheritedTypeReprs = readInheritedTypes(
            inheritance: protocolSyntax.inheritanceClause
        )

        `protocol`.members = readMembers(block: protocolSyntax.memberBlock, on: `protocol`)

        return `protocol`
    }

    static func readClass(
        class classSyntax: ClassDeclSyntax,
        on context: some DeclContext
    ) -> ClassDecl? {
        let name = classSyntax.name.text

        let `class` = ClassDecl(context: context, name: name)

        `class`.modifiers = readModifires(decls: classSyntax.modifiers)

        `class`.syntaxGenericParams = readGenericParamList(
            clause: classSyntax.genericParameterClause, on: `class`
        )

        `class`.inheritedTypeReprs = readInheritedTypes(
            inheritance: classSyntax.inheritanceClause
        )

        `class`.members = readMembers(
            block: classSyntax.memberBlock, on: `class`
        )

        return `class`
    }

    static func readCaseElements(
        decl: DeclSyntax,
        on context: some DeclContext
    ) -> [EnumCaseElementDecl]? {
        guard let caseDecl = decl.as(EnumCaseDeclSyntax.self),
              let `enum` = context.asEnum else { return nil }

        return caseDecl.elements.map { (element) in
            readCaseElement(element: element, on: `enum`)
        }
    }

    static func readCaseElement(
        element elementSyntax: EnumCaseElementSyntax,
        on enum: EnumDecl
    ) -> EnumCaseElementDecl {
        let name = Reader.unescapeIdentifier(elementSyntax.name.text)

        var rawValue: EnumCaseElementDecl.LiteralExpr?
        if let string = elementSyntax.rawValue?.value.as(StringLiteralExprSyntax.self),
           let value = string.segments.first?.as(StringSegmentSyntax.self)?.content.text {
            rawValue = .string(value)
        } else if let integer = elementSyntax.rawValue?.value.as(IntegerLiteralExprSyntax.self),
                  let value = Int(integer.literal.text) {
            rawValue = .integer(value)
        } else if let prefix = elementSyntax.rawValue?.value.as(PrefixOperatorExprSyntax.self),
                  let integer = prefix.expression.as(IntegerLiteralExprSyntax.self),
                  let value = Int(integer.literal.text) {
            rawValue = .integer(-value)
        }
        
        let element = EnumCaseElementDecl(enum: `enum`, name: name, rawValue: rawValue)

        element.associatedValues = Reader.readParamList(
            paramList: (elementSyntax.parameterClause?.parameters),
            on: element
        )

        return element
    }

    static func readAssociatedType(
        decl: DeclSyntax,
        on context: some DeclContext
    ) -> AssociatedTypeDecl? {
        guard let decl = decl.as(AssociatedTypeDeclSyntax.self),
              let `protocol` = context.asProtocol else { return nil }
        return readAssociatedType(associatedType: decl, on: `protocol`)
    }

    static func readAssociatedType(
        associatedType associatedTypeSyntax: AssociatedTypeDeclSyntax,
        on `protocol`: ProtocolDecl
    ) -> AssociatedTypeDecl {
        let name = associatedTypeSyntax.name.text

        let associatedType = AssociatedTypeDecl(protocol: `protocol`, name: name)
        associatedType.inheritedTypeReprs = Reader.readInheritedTypes(
            inheritance: associatedTypeSyntax.inheritanceClause
        )
        return associatedType
    }

    static func readParamList(
        paramList paramListSyntax: EnumCaseParameterListSyntax?,
        on context: some DeclContext
    ) -> [CaseParamDecl] {
        guard let paramListSyntax else { return [] }
        return paramListSyntax.compactMap { (paramSyntax) in
            readParam(param: paramSyntax, on: context)
        }
    }

    static func readParam(
        param paramSyntax: EnumCaseParameterSyntax,
        on context: some DeclContext
    ) -> CaseParamDecl? {
        var outerName: String? = nil
        let name: String?

        if let first = paramSyntax.firstName {
            if let second = paramSyntax.secondName {
                outerName = first.text
                name = second.text
            } else {
                name = first.text
            }
        } else {
            name = nil
        }

        guard let typeRepr = TypeReprReader.read(type: paramSyntax.type) else { return nil }

        return CaseParamDecl(
            context: context,
            syntaxOuterName: outerName,
            syntaxName: name,
            typeRepr: typeRepr
        )
    }

    static func readParamList(
        paramList paramListSyntax: FunctionParameterListSyntax?,
        on context: some DeclContext
    ) -> [FuncParamDecl] {
        guard let paramListSyntax else { return [] }
        return paramListSyntax.compactMap { (paramSyntax) in
            readParam(param: paramSyntax, on: context)
        }
    }

    static func readParam(
        param paramSyntax: FunctionParameterSyntax,
        on context: some DeclContext
    ) -> FuncParamDecl? {
        var outerName: String? = nil
        let name: String

        let first = paramSyntax.firstName
        if let second = paramSyntax.secondName {
            outerName = first.text
            name = second.text
        } else {
            name = first.text
        }

        guard let typeRepr = TypeReprReader.read(type: paramSyntax.type) else { return nil }

        return FuncParamDecl(
            context: context,
            syntaxOuterName: outerName,
            syntaxName: name,
            typeRepr: typeRepr
        )
    }

    static func readVars(decl: DeclSyntax, on context: some DeclContext) -> [VarDecl]? {
        guard let decl = decl.as(VariableDeclSyntax.self) else { return nil }
        return readVars(var: decl, on: context)
    }

    static func readVars(
        `var`: VariableDeclSyntax,
        on context: some DeclContext
    ) -> [VarDecl] {
        return `var`.bindings.compactMap { (binding) in
            readVar(var: `var`, binding: binding, on: context)
        }
    }

    static func readVar(
        `var` varSyntax: VariableDeclSyntax,
        binding: PatternBindingSyntax,
        on context: some DeclContext
    ) -> VarDecl? {
        guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        guard let kind = VarKind(rawValue: varSyntax.bindingSpecifier.text) else {
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

        if let accessor = binding.accessorBlock {
            `var`.accessors += readVarAccessor(accessor: accessor.accessors, on: `var`)
        }

        return `var`
    }

    static func readVarAccessor(
        accessor: AccessorBlockSyntax.Accessors,
        on `var`: VarDecl
    ) -> [AccessorDecl] {
        switch accessor {
        case .getter:
            let accessor = AccessorDecl(var: `var`, modifiers: [], kind: .get)
            return [accessor]
        case .accessors(let declList):
            return declList.compactMap {
                readAccessor(accessor: $0, on: `var`)
            }
        }
    }

    static func readAccessor(
        accessor accessorSyntax: AccessorDeclSyntax,
        on `var`: VarDecl
    ) -> AccessorDecl? {
        guard let kind = AccessorKind(rawValue: accessorSyntax.accessorSpecifier.text) else {
            return nil
        }

        var modifiers = ModifierReader()
        modifiers.read(decl: accessorSyntax.modifier)
        modifiers.read(token: accessorSyntax.effectSpecifiers?.asyncSpecifier)
        modifiers.read(token: accessorSyntax.effectSpecifiers?.throwsSpecifier)

        return AccessorDecl(var: `var`, modifiers: modifiers.modifiers, kind: kind)
    }

    static func readFunc(decl: DeclSyntax, on context: some DeclContext) -> FuncDecl? {
        guard let decl = decl.as(FunctionDeclSyntax.self) else { return nil }
        return readFunc(function: decl, on: context)
    }

    static func readFunc(
        function functionSyntax: FunctionDeclSyntax,
        on context: some DeclContext
    ) -> FuncDecl {
        let name = functionSyntax.name.text

        var modifiers = ModifierReader()
        modifiers.read(decls: functionSyntax.modifiers)
        modifiers.read(token: functionSyntax.signature.effectSpecifiers?.asyncSpecifier)
        modifiers.read(token: functionSyntax.signature.effectSpecifiers?.throwsSpecifier)

        let `func` = FuncDecl(
            context: context,
            modifiers: modifiers.modifiers,
            name: name
        )

        `func`.parameters = functionSyntax.signature.parameterClause.parameters.compactMap { (param) in
            readParam(param: param, on: `func`)
        }

        `func`.resultTypeRepr = functionSyntax.signature.returnClause.flatMap { (returnTypeSyntax) in
            TypeReprReader.read(type: returnTypeSyntax.type)
        }

        return `func`
    }

    static func readInit(decl: DeclSyntax, on context: some DeclContext) -> InitDecl? {
        guard let decl = decl.as(InitializerDeclSyntax.self) else { return nil }
        return readInit(initializer: decl, on: context)
    }

    static func readInit(
        initializer initializerSyntax: InitializerDeclSyntax,
        on context: some DeclContext
    ) -> InitDecl {
        let signatureSyntax = initializerSyntax.signature

        var modifiers = ModifierReader()
        modifiers.read(decls: initializerSyntax.modifiers)
        modifiers.read(token: signatureSyntax.effectSpecifiers?.asyncSpecifier)
        modifiers.read(token: signatureSyntax.effectSpecifiers?.throwsSpecifier)

        let `init` = InitDecl(context: context, modifiers: modifiers.modifiers)
        `init`.parameters = signatureSyntax.parameterClause.parameters.compactMap { (param) in
            readParam(param: param, on: `init`)
        }

        return `init`
    }

    static func readModifires(
        decls: DeclModifierListSyntax?
    ) -> [DeclModifier] {
        var reader = ModifierReader()
        reader.read(decls: decls)
        return reader.modifiers
    }

    static func readGenericParamList(
        clause: GenericParameterClauseSyntax?,
        on context: some DeclContext
    ) -> GenericParamList {
        guard let clause else {
            return GenericParamList([])
        }
        return readGenericParamList(clause: clause, on: context)
    }

    static func readGenericParamList(
        clause: GenericParameterClauseSyntax,
        on context: some DeclContext
    ) -> GenericParamList {
        return GenericParamList(
            clause.parameters.map { (paramSyntax) in
                readGenericParam(param: paramSyntax, on: context)
            }
        )
    }

    static func readGenericParam(
        param paramSyntax: GenericParameterSyntax,
        on context: some DeclContext
    ) -> GenericParamDecl {
        let param = GenericParamDecl(
            context: context,
            name: paramSyntax.name.text
        )
        param.inheritedTypeReprs = TypeReprReader.read(type: paramSyntax.inheritedType)
            .toArray()
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
            TypeReprReader.read(type: $0.argument)
        }
    }

    static func readInheritedTypes(
        inheritance: InheritanceClauseSyntax?
    ) -> [any TypeRepr] {
        guard let inheritance else { return [] }
        return readInheritedTypes(inheritance: inheritance)
    }

    static func readInheritedTypes(
        inheritance: InheritanceClauseSyntax
    ) -> [any TypeRepr] {
        return inheritance.inheritedTypes.compactMap { (type) in
            TypeReprReader.read(type: type.type)
        }
    }

    static func readTypeAlias(decl: DeclSyntax, on context: some DeclContext) -> TypeAliasDecl? {
        guard let decl = decl.as(TypeAliasDeclSyntax.self) else { return nil }

        let name = decl.name.text

        let underlyingSyntax = decl.initializer

        guard let underlying = TypeReprReader.read(type: underlyingSyntax.value) else { return nil }

        let alias = TypeAliasDecl(
            context: context,
            name: name,
            underlyingTypeRepr: underlying
        )

        alias.modifiers = readModifires(decls: decl.modifiers)

        alias.syntaxGenericParams = readGenericParamList(clause: decl.genericParameterClause, on: alias)

        return alias
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
        let isScoped = importSyntax.importKindSpecifier != nil

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

