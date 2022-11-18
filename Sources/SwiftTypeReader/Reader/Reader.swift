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
            }

//            if let type = Readers.readTypeDeclaration(context: context, declaration: decl) {
//                source.types.append(type)
//            } else if let `import` = Readers.readImportDeclaration(context: context, declaration: decl) {
//                source.imports.append(`import`)
//            }
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

    static func readTypeRepr(
        type: TypeSyntax
    ) -> (any TypeRepr)? {
        if let member = type.as(MemberTypeIdentifierSyntax.self) {
            guard let base = readTypeRepr(
                type: member.baseType
            ),
                  let args = readOptionalGenericArguments(
                    clause: member.genericArgumentClause
                  ),
                  var idents = decomposeTypeReprToIdents(typeRepr: base)
            else { return nil }

            idents.append(
                IdentTypeRepr(
                    name: member.name.text,
                    genericArgs: args
                )
            )

            return ChainedTypeRepr(idents)
        }

        if let simple = type.as(SimpleTypeIdentifierSyntax.self) {
            guard let args = readOptionalGenericArguments(
                clause: simple.genericArgumentClause
            ) else { return nil }

            return IdentTypeRepr(
                name: simple.name.text,
                genericArgs: args
            )
        }

        if let optional = type.as(OptionalTypeSyntax.self) {
            guard let wrapped = readTypeRepr(
                type: optional.wrappedType
            ) else { return nil }

            return IdentTypeRepr(
                name: "Optional",
                genericArgs: [wrapped]
            )
        } else if let array = type.as(ArrayTypeSyntax.self) {
            guard let element = readTypeRepr(
                type: array.elementType
            ) else { return nil }

            return IdentTypeRepr(
                name: "Array",
                genericArgs: [element]
            )
        } else if let dictionary = type.as(DictionaryTypeSyntax.self) {
            guard let key = readTypeRepr(
                type: dictionary.keyType
            ),
                  let value = readTypeRepr(
                    type: dictionary.valueType
                  ) else { return nil }

            return IdentTypeRepr(
                name: "Dictionary",
                genericArgs: [key, value]
            )
        } else {
            return nil
        }
    }

    static func decomposeTypeReprToIdents(typeRepr: any TypeRepr) -> [IdentTypeRepr]? {
        switch typeRepr {
        case let repr as IdentTypeRepr: return [repr]
        case let repr as ChainedTypeRepr: return repr.items
        default: return nil
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

    static func isStoredPropertyAccessor(accessor: Syntax) -> Bool {
        if let _ = accessor.as(CodeBlockSyntax.self) {
            return false
        } else if let accessors = accessor.as(AccessorBlockSyntax.self) {
            return accessors.accessors.allSatisfy { (accsessor) in
                isStoredPropertyAccessor(name: accsessor.accessorKind.text)
            }
        } else {
            return false
        }
    }

    static func isStoredPropertyAccessor(name: String) -> Bool {
        return name == "willSet" || name == "didSet"
    }
}

