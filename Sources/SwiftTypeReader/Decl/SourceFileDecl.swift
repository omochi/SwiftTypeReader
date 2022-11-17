import Foundation

public final class SourceFileDecl: Decl & DeclContext {
    public init(
        module: ModuleDecl,
        file: URL
    ) {
        self.module = module
        self.file = file
        self.imports = []
        self.types = []
    }

    public unowned var module: ModuleDecl
    public var file: URL
    public var context: (any DeclContext)? { module }

    public var imports: [ImportDecl2]
    public var types: [any NominalTypeDecl]

    public func findOwn(name: String, options: LookupOptions) -> (any Decl)? {
        if options.type {
            if let type = types.first(where: { $0.name == name }) {
                return type
            }
        }
        return nil
    }
}
