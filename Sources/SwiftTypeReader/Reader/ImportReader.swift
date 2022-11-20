import Foundation
import SwiftSyntax

struct ImportReader {
    static func read(
        `import`: ImportDeclSyntax,
        on source: SourceFile
    ) -> ImportDecl2 {
        let name = `import`.path.description
        return ImportDecl2(
            source: source,
            name: name
        )
    }
}
