import Foundation
import CodegenKit

struct BaseTypeRenderer: Renderer {
    struct File {
        var name: String
        var kind: Node.Kind
    }

    var defs: Definitions

    var files: [File] = [
        .init(name: "Decl.swift", kind: .decl),
        .init(name: "DeclContext.swift", kind: .declContext),
        .init(name: "SType.swift", kind: .type),
        .init(name: "TypeRepr.swift", kind: .typeRepr)
    ]

    func isTarget(file: URL) -> Bool {
        files.contains { $0.name == file.lastPathComponent }
    }

    func render(template: inout CodeTemplate, file: URL, on runner: CodegenRunner) throws {
        let kind = files.first { $0.name == file.lastPathComponent }!.kind

        template["as"] = asCast(kind: kind)
    }

    func asCast(kind: Node.Kind) -> String {
        let nodes = defs.nodes(kind: kind)

        let lines: [String] = nodes.map { (node) in
            return """
public var as\(node.stem.pascal): \(node.optionalTypeName) { self as? \(node.typeName) }
"""
        }

        return lines.joined(separator: "\n")
    }
}
