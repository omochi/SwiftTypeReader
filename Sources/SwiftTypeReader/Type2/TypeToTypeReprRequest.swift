struct TypeToTypeReprImpl {
    var type: any SType2
    var containsModule: Bool

    func convert() -> any TypeRepr {
        switch type {
        case let type as ErrorType:
            return ErrorTypeRepr(text: type.description)
        case let type as GenericParamType2:
            return IdentTypeRepr([.init(name: type.name)])
        case let type as MetatypeType:
            return MetatypeTypeRepr(
                instance: type.instance.toTypeRepr(containsModule: containsModule)
            )
        case let type as ModuleType:
            return IdentTypeRepr([.init(name: type.name)])
        case let type as any NominalType:
            return convert(type: type)
        default:
            return ErrorTypeRepr(text: "(ERROR)")
        }
    }

    private func convert(type: any NominalType) -> IdentTypeRepr {
        var reversedElements: [IdentTypeRepr.Element] = []

        reversedElements.append(
            makeElement(type: type)
        )

        var nextParent = type.parent
        while let parent = nextParent as? any NominalType {
            reversedElements.append(
                makeElement(type: parent)
            )
            nextParent = parent.parent
        }

        if containsModule {
            reversedElements.append(
                .init(name: type.nominalTypeDecl.moduleContext.name)
            )
        }

        return IdentTypeRepr(reversedElements.reversed())
    }

    private func makeElement(type: any NominalType) -> IdentTypeRepr.Element {
        return .init(
            name: type.name,
            genericArgs: type.genericArgs.map { (arg) in
                arg.toTypeRepr(containsModule: containsModule)
            }
        )
    }
}
