import Foundation

public final class SourceFileDecl: Decl & DeclContext {
    public init(
        module: ModuleDecl,
        file: URL
    ) {
        self.module = module
        self.file = file
    }

    public unowned var module: ModuleDecl
    public var file: URL
    public var context: (any DeclContext)? { module }
}
