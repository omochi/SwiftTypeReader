import Foundation
import SwiftSyntax
import SwiftParser
import SwiftIfConfig

public struct Reader {
    public var context: Context
#if !os(WASI)
    public var fileManager: FileManager
#endif
    public var module: Module
    public var buildConfiguration: (any BuildConfiguration)?

#if !os(WASI)
    public init(
        context: Context,
        fileManager: FileManager = .default,
        module: Module? = nil,
        buildConfiguration: (any BuildConfiguration)? = nil
    ) {
        self.context = context
        self.fileManager = fileManager
        self.module = module ?? context.getOrCreateModule(name: "main")
        self.buildConfiguration = buildConfiguration
    }

#else
    public init(
        context: Context,
        module: Module? = nil,
        buildConfiguration: (any BuildConfiguration)?
    ) {
        self.context = context
        self.module = module ?? context.getOrCreateModule(name: "main")
        self.buildConfiguration = buildConfiguration
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
        return Reader.read(source: source, file: file, on: module, buildConfiguration: buildConfiguration)
    }

    static func unescapeIdentifier(_ str: String) -> String {
        return str.trimmingCharacters(in: ["`"])
    }

    static func read(
        source sourceString: String, file: URL,
        on module: Module,
        buildConfiguration: (any BuildConfiguration)?
    ) -> SourceFile {
        let sourceSyntax: SourceFileSyntax = Parser.parse(source: sourceString)
        let source = SourceFile(module: module, file: file)
        let configuration: any BuildConfiguration = buildConfiguration ?? StaticBuildConfiguration(
            languageVersion: VersionTuple(components: [6, 0]),
            compilerVersion: VersionTuple(components: [6, 0])
        )
        ReaderVisitor(
            source: source,
            configuration: configuration
        ).walk(sourceSyntax)
        module.sources.append(source)

        return source
    }

    private final class ReaderVisitor: ActiveSyntaxVisitor {
        let source: SourceFile
        var contextStack: [any DeclContext]
        init(
            source: SourceFile,
            configuration: some BuildConfiguration
        ) {
            self.source = source
            self.contextStack = [source]
            super.init(viewMode: .sourceAccurate, configuration: configuration)
        }

        var currentContext: any DeclContext {
            contextStack.last!
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            let decl = Reader.readStruct(struct: node, on: currentContext)
            currentContext.append(decl: decl)
            contextStack.append(decl)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            contextStack.removeLast()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            let decl = Reader.readEnum(enum: node, on: currentContext)
            currentContext.append(decl: decl)
            contextStack.append(decl)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            contextStack.removeLast()
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            let decl = Reader.readProtocol(protocol: node, on: currentContext)
            currentContext.append(decl: decl)
            contextStack.append(decl)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            contextStack.removeLast()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            let decl = Reader.readClass(class: node, on: currentContext)
            currentContext.append(decl: decl)
            contextStack.append(decl)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            contextStack.removeLast()
        }

        override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let decl = Reader.readTypeAlias(typeAlias: node, on: currentContext) else {
                return .skipChildren
            }
            currentContext.append(decl: decl)
            return .skipChildren
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            Reader.readVars(var: node, on: currentContext).forEach {
                currentContext.append(decl: $0)
            }
            return .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            let decl = Reader.readFunc(function: node, on: currentContext)
            currentContext.append(decl: decl)
            return .skipChildren
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            let decl = Reader.readInit(initializer: node, on: currentContext)
            currentContext.append(decl: decl)
            return .skipChildren
        }

        override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
            Reader.readCaseElements(enumCase: node, on: currentContext).forEach {
                currentContext.append(decl: $0)
            }
            return .skipChildren
        }

        override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let decl = Reader.readAssociatedType(associatedType: node, on: currentContext) else {
                return .skipChildren
            }
            currentContext.append(decl: decl)
            return .skipChildren
        }

        override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
            if let decl = Reader.readImport(import: node, on: source) {
                source.imports.append(decl)
            }
            return .skipChildren
        }
    }

    static func readStruct(struct structSyntax: StructDeclSyntax, on context: some DeclContext) -> StructDecl {
        let name = structSyntax.name.text

        let `struct` = StructDecl(context: context, name: name)

        `struct`.comment = structSyntax.leadingTrivia.description

        `struct`.attributes = readAttributes(list: structSyntax.attributes)
        `struct`.modifiers = readModifires(decls: structSyntax.modifiers)
        
        `struct`.syntaxGenericParams = readGenericParamList(
            clause: structSyntax.genericParameterClause, on: `struct`
        )

        `struct`.inheritedTypeReprs = readInheritedTypes(
            inheritance: structSyntax.inheritanceClause
        )

        return `struct`
    }

    static func readEnum(enum enumSyntax: EnumDeclSyntax, on context: some DeclContext) -> EnumDecl {
        let name = enumSyntax.name.text

        let `enum` = EnumDecl(context: context, name: name)

        `enum`.comment = enumSyntax.leadingTrivia.description

        `enum`.attributes = readAttributes(list: enumSyntax.attributes)
        `enum`.modifiers = readModifires(decls: enumSyntax.modifiers)

        `enum`.syntaxGenericParams = readGenericParamList(
            clause: enumSyntax.genericParameterClause, on: `enum`
        )

        `enum`.inheritedTypeReprs = readInheritedTypes(
            inheritance: enumSyntax.inheritanceClause
        )

        return `enum`
    }

    static func readProtocol(
        `protocol` protocolSyntax: ProtocolDeclSyntax,
        on context: some DeclContext
    ) -> ProtocolDecl {
        let name = protocolSyntax.name.text

        let `protocol` = ProtocolDecl(context: context, name: name)

        `protocol`.comment = protocolSyntax.leadingTrivia.description

        `protocol`.attributes = readAttributes(list: protocolSyntax.attributes)
        `protocol`.modifiers = readModifires(decls: protocolSyntax.modifiers)

        `protocol`.inheritedTypeReprs = readInheritedTypes(
            inheritance: protocolSyntax.inheritanceClause
        )

        return `protocol`
    }

    static func readClass(
        class classSyntax: ClassDeclSyntax,
        on context: some DeclContext
    ) -> ClassDecl {
        let name = classSyntax.name.text

        let `class` = ClassDecl(context: context, name: name)

        `class`.comment = classSyntax.leadingTrivia.description

        `class`.attributes = readAttributes(list: classSyntax.attributes)
        `class`.modifiers = readModifires(decls: classSyntax.modifiers)

        `class`.syntaxGenericParams = readGenericParamList(
            clause: classSyntax.genericParameterClause, on: `class`
        )

        `class`.inheritedTypeReprs = readInheritedTypes(
            inheritance: classSyntax.inheritanceClause
        )

        return `class`
    }

    static func readCaseElements(
        enumCase caseSyntax: EnumCaseDeclSyntax,
        on context: some DeclContext
    ) -> [EnumCaseElementDecl] {
        guard let `enum` = context.asEnum else { return [] }

        return caseSyntax.elements.map { (element) in
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
        associatedType associatedTypeSyntax: AssociatedTypeDeclSyntax,
        on context: some DeclContext
    ) -> AssociatedTypeDecl? {
        guard let `protocol` = context.asProtocol else { return nil }
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

        let `var` = VarDecl(
            context: context,
            kind: kind,
            name: name,
            typeRepr: typeRepr
        )
        `var`.attributes = readAttributes(list: varSyntax.attributes)
        `var`.modifiers = readModifires(decls: varSyntax.modifiers)

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
            let accessor = AccessorDecl(var: `var`, attributes: [], modifiers: [], kind: .get)
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

        var attributes = AttributeReader()
        attributes.read(list: accessorSyntax.attributes)

        var modifiers = ModifierReader()
        modifiers.read(decl: accessorSyntax.modifier)
        modifiers.read(token: accessorSyntax.effectSpecifiers?.asyncSpecifier)
        modifiers.read(token: accessorSyntax.effectSpecifiers?.throwsClause?.throwsSpecifier)

        return AccessorDecl(var: `var`, attributes: attributes.attributes, modifiers: modifiers.modifiers, kind: kind)
    }

    static func readFunc(
        function functionSyntax: FunctionDeclSyntax,
        on context: some DeclContext
    ) -> FuncDecl {
        let name = functionSyntax.name.text

        var modifiers = ModifierReader()
        modifiers.read(decls: functionSyntax.modifiers)
        modifiers.read(token: functionSyntax.signature.effectSpecifiers?.asyncSpecifier)
        modifiers.read(token: functionSyntax.signature.effectSpecifiers?.throwsClause?.throwsSpecifier)

        let `func` = FuncDecl(
            context: context,
            name: name
        )

        `func`.attributes = readAttributes(list: functionSyntax.attributes)
        `func`.modifiers = modifiers.modifiers

        `func`.parameters = functionSyntax.signature.parameterClause.parameters.compactMap { (param) in
            readParam(param: param, on: `func`)
        }

        `func`.resultTypeRepr = functionSyntax.signature.returnClause.flatMap { (returnTypeSyntax) in
            TypeReprReader.read(type: returnTypeSyntax.type)
        }

        return `func`
    }

    static func readInit(
        initializer initializerSyntax: InitializerDeclSyntax,
        on context: some DeclContext
    ) -> InitDecl {
        let signatureSyntax = initializerSyntax.signature

        var modifiers = ModifierReader()
        modifiers.read(decls: initializerSyntax.modifiers)
        modifiers.read(token: signatureSyntax.effectSpecifiers?.asyncSpecifier)
        modifiers.read(token: signatureSyntax.effectSpecifiers?.throwsClause?.throwsSpecifier)

        let `init` = InitDecl(context: context, modifiers: modifiers.modifiers)
        `init`.attributes = readAttributes(list: initializerSyntax.attributes)
        `init`.parameters = signatureSyntax.parameterClause.parameters.compactMap { (param) in
            readParam(param: param, on: `init`)
        }

        return `init`
    }

    static func readAttributes(
        list: AttributeListSyntax
    ) -> [Attribute] {
        var reader = AttributeReader()
        reader.read(list: list)
        return reader.attributes
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
            guard let type = $0.argument.as(TypeSyntax.self) else { return nil }
            return TypeReprReader.read(type: type)
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

    static func readTypeAlias(typeAlias typeAliasSyntax: TypeAliasDeclSyntax, on context: some DeclContext) -> TypeAliasDecl? {
        let name = typeAliasSyntax.name.text

        let underlyingSyntax = typeAliasSyntax.initializer

        guard let underlying = TypeReprReader.read(type: underlyingSyntax.value) else { return nil }

        let alias = TypeAliasDecl(
            context: context,
            name: name,
            underlyingTypeRepr: underlying
        )

        alias.attributes = readAttributes(list: typeAliasSyntax.attributes)
        alias.modifiers = readModifires(decls: typeAliasSyntax.modifiers)

        alias.syntaxGenericParams = readGenericParamList(clause: typeAliasSyntax.genericParameterClause, on: alias)

        return alias
    }

    static func readImport(
        `import` importSyntax: ImportDeclSyntax,
        on source: SourceFile
    ) -> ImportDecl? {
        let isScoped = importSyntax.importKindSpecifier != nil

        let path = importSyntax.path.map { $0.name.text }
        guard !path.isEmpty else { return nil }

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

extension DeclContext {
    fileprivate func append(decl: any ValueDecl) {
        if let source = self.asSourceFile {
            if let type = decl.asGenericType {
                source.types.append(type)
            } else if let `func` = decl.asFunc {
                source.funcs.append(`func`)
            }
        } else if let `struct` = self.asStruct {
            `struct`.members.append(decl)
        } else if let `enum` = self.asEnum {
            `enum`.members.append(decl)
        } else if let `protocol` = self.asProtocol {
            `protocol`.members.append(decl)
        } else if let `class` = self.asClass {
            `class`.members.append(decl)
        }
    }
}
