import Foundation

public struct SourceFile {
    public var file: URL
    public var types: [SType] = []
    public var imports: [ImportDecl] = []

    public init(
        file: URL
    ) {
        self.file = file
    }
}

