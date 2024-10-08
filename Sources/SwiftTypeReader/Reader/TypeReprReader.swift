import SwiftSyntax

struct TypeReprReader {
    static func read(syntax: Syntax?) -> (any TypeRepr)? {
        guard let syntax else { return nil }
        return read(syntax: syntax)
    }

    static func read(syntax: Syntax) -> (any TypeRepr)? {
        guard let type = syntax.as(TypeSyntax.self) else { return nil }
        return read(type: type)
    }

    static func read(type: TypeSyntax?) -> (any TypeRepr)? {
        guard let type else { return nil }
        return read(type: type)
    }

    static func read(type: TypeSyntax) -> (any TypeRepr)? {
        if let member = type.as(MemberTypeSyntax.self) {
            return read(member: member)
        } else if let simple = type.as(IdentifierTypeSyntax.self) {
            return read(simple: simple)
        } else if let composition = type.as(CompositionTypeSyntax.self) {
            return read(composition: composition)
        } else if let tuple = type.as(TupleTypeSyntax.self) {
            return read(tuple: tuple)
        } else if let optional = type.as(OptionalTypeSyntax.self) {
            return read(optional: optional)
        } else if let array = type.as(ArrayTypeSyntax.self) {
            return read(array: array)
        } else if let dictionary = type.as(DictionaryTypeSyntax.self) {
            return read(dictionary: dictionary)
        } else if let function = type.as(FunctionTypeSyntax.self) {
            return read(function: function)
        } else {
            return nil
        }
    }

    static func read(member: MemberTypeSyntax) -> (any TypeRepr)? {
        guard var repr = read(
            type: member.baseType
        )?.asIdent,
              let args = Reader.readGenericArguments(
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

    static func read(simple: IdentifierTypeSyntax) -> (any TypeRepr)? {
        guard let args = Reader.readGenericArguments(
            clause: simple.genericArgumentClause
        ) else { return nil }

        return IdentTypeRepr(
            name: simple.name.text,
            genericArgs: args
        )
    }

    static func read(composition: CompositionTypeSyntax) -> (any TypeRepr)? {
        return CompositionTypeRepr(
            elements: composition.elements.compactMap { (element) in
                read(type: element.type)
            }
        )
    }

    static func read(tuple: TupleTypeSyntax) -> (any TypeRepr)? {
        return TupleTypeRepr(
            elements: tuple.elements.compactMap { (element) in
                read(type: element.type)
            }
        )
    }

    static func read(optional: OptionalTypeSyntax) -> (any TypeRepr)? {
        guard let wrapped = read(
            type: optional.wrappedType
        ) else { return nil }

        return IdentTypeRepr(
            name: "Optional",
            genericArgs: [wrapped]
        )
    }

    static func read(array: ArrayTypeSyntax) -> (any TypeRepr)? {
        guard let element = read(
            type: array.element
        ) else { return nil }

        return IdentTypeRepr(
            name: "Array",
            genericArgs: [element]
        )
    }

    static func read(dictionary: DictionaryTypeSyntax) -> (any TypeRepr)? {
        guard let key = read(
            type: dictionary.key
        ),
              let value = read(
                type: dictionary.value
              ) else { return nil }

        return IdentTypeRepr(
            name: "Dictionary",
            genericArgs: [key, value]
        )
    }

    static func read(function: FunctionTypeSyntax) -> FunctionTypeRepr? {
        guard let params = read(params: function.parameters),
              let result = read(type: function.returnClause.type) else {
            return nil
        }
        return FunctionTypeRepr(
            params: params,
            hasAsync: function.effectSpecifiers?.asyncSpecifier != nil,
            hasThrows: function.effectSpecifiers?.throwsClause?.throwsSpecifier != nil,
            result: result
        )
    }

    static func read(params: TupleTypeElementListSyntax) -> TupleTypeRepr? {
        return TupleTypeRepr(
            elements: params.compactMap { (param) in
                read(param: param)
            }
        )
    }

    static func read(param: TupleTypeElementSyntax) -> (any TypeRepr)? {
        return read(type: param.type)
    }
}
