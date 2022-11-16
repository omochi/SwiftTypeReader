import Foundation

public struct SourceFile {
    public unowned var module: Module
    public var file: URL
    public var types: [SType] = []
    public var imports: [ImportDecl] = []

    public init(
        module: Module,
        file: URL
    ) {
        self.module = module
        self.file = file
    }
}

