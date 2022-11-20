import Foundation
import SwiftSyntax

struct ImportReader {
    static func read(
        `import` importSyntax: ImportDeclSyntax,
        on source: SourceFile
    ) -> ImportDecl {
        let isScoped = importSyntax.importKind != nil

        let path = importSyntax.path.map { $0.name.text }

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
