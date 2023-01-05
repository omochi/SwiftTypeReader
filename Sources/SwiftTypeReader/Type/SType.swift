/*
 To avoid ambiguity with `Type` keyword for metatype,
 name this type to SType.

 S means Swift.
 */
public protocol SType: Hashable & CustomStringConvertible {
}

extension SType {
    // @codegen(as) MARK: - cast
    public var asClass: ClassType? { self as? ClassType }
    public var asDependentMember: DependentMemberType? { self as? DependentMemberType }
    public var asEnum: EnumType? { self as? EnumType }
    public var asError: ErrorType? { self as? ErrorType }
    public var asFunction: FunctionType? { self as? FunctionType }
    public var asGenericParam: GenericParamType? { self as? GenericParamType }
    public var asMetatype: MetatypeType? { self as? MetatypeType }
    public var asModule: ModuleType? { self as? ModuleType }
    public var asNominal: (any NominalType)? { self as? any NominalType }
    public var asProtocol: ProtocolType? { self as? ProtocolType }
    public var asStruct: StructType? { self as? StructType }
    public var asTypeAlias: TypeAliasType? { self as? TypeAliasType }
    // @end

    public var description: String {
        switch self {
        case let self as ErrorType:
            return self.errorTypeDescription
        default:
            return toTypeRepr(containsModule: false).description
        }
    }

    public func toTypeRepr(
        containsModule: Bool
    ) -> any TypeRepr {
        do {
            return try TypeToTypeReprImpl(
                type: self,
                containsModule: containsModule
            ).convert()
        } catch {
            return ErrorTypeRepr(text: "\(error)")
        }
    }

    public var typeDecl: (any TypeDecl)? {
        switch self {
        case let type as ModuleType: return type.decl
        case let type as any NominalType: return type.nominalTypeDecl
        case let type as TypeAliasType: return type.decl
        case let type as GenericParamType: return type.decl
        case let type as DependentMemberType: return type.decl
        default: return nil
        }
    }
}
