import Foundation
import SwiftSyntax

final class ImportReader {
    private let module: Module
    private let file: URL?
    private let location: Location

    init(
        module: Module,
        file: URL?,
        location: Location
    ) {
        self.module = module
        self.file = file
        self.location = location
    }

    func read(importDecl: ImportDeclSyntax) -> ImportDecl {
        return ImportDecl(
            module: module,
            file: file,
            location: location,
            target: .module(name: importDecl.path.description)
        )
    }
}
