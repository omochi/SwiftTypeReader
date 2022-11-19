import Foundation
import SwiftSyntax

struct ImportReader {
    var reader: Reader
    init(
        reader: Reader
    ) {
        self.reader = reader
    }

    func read(
        `import`: ImportDeclSyntax,
        on source: SourceFileDecl
    ) -> ImportDecl2 {
        let name = `import`.path.description
        return ImportDecl2(
            source: source,
            name: name
        )
    }
}
