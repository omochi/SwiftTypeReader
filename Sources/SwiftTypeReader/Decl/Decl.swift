import Foundation

public protocol Decl: AnyObject & HashableFromIdentity & _DeclParentContextHolder {
}

extension Decl {
    // @codegen(as) MARK: - cast
    public var asAccessor: AccessorDecl? { self as? AccessorDecl }
    public var asAssociatedType: AssociatedTypeDecl? { self as? AssociatedTypeDecl }
    public var asClass: ClassDecl? { self as? ClassDecl }
    public var asEnumCaseElement: EnumCaseElementDecl? { self as? EnumCaseElementDecl }
    public var asEnum: EnumDecl? { self as? EnumDecl }
    public var asFunc: FuncDecl? { self as? FuncDecl }
    public var asGenericParam: GenericParamDecl? { self as? GenericParamDecl }
    public var asGenericType: (any GenericTypeDecl)? { self as? any GenericTypeDecl }
    public var asImport: ImportDecl? { self as? ImportDecl }
    public var asModule: Module? { self as? Module }
    public var asNominalType: (any NominalTypeDecl)? { self as? any NominalTypeDecl }
    public var asParam: ParamDecl? { self as? ParamDecl }
    public var asProtocol: ProtocolDecl? { self as? ProtocolDecl }
    public var asSourceFile: SourceFile? { self as? SourceFile }
    public var asStruct: StructDecl? { self as? StructDecl }
    public var asTypeAlias: TypeAliasDecl? { self as? TypeAliasDecl }
    public var asType: (any TypeDecl)? { self as? any TypeDecl }
    public var asValue: (any ValueDecl)? { self as? any ValueDecl }
    public var asVar: VarDecl? { self as? VarDecl }
    // @end

    public var innermostContext: any DeclContext {
        if let self = self as? any DeclContext {
            return self
        }
        return parentContext!
    }
}
