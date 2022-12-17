import Foundation
import CodegenKit

struct TypeTransformerRenderer: Renderer {
    var defs: Definitions
    var writer = SwiftWriter()

    func isTarget(file: URL) -> Bool {
        file.lastPathComponent == "TypeTransformer.swift"
    }

    func render(template: inout CodeTemplate, file: URL, on runner: CodegenRunner) throws {
        template["dispatch"] = dispatch()
        template["visit"] = visit()
        template["visitImpl"] = visitImpl()
    }

    func types() -> [Node] {
        defs.nodes(kind: .type).filter { !$0.attributes.contains(.protocol) }
    }

    func dispatch() -> String {
        var lines: [String] = []

        lines.append("""
private func dispatch(type: any SType) -> any SType {
    switch type {
""")

        lines += types().map { (type) in
            return """
    case let t as \(type.typeName): return visitImpl(\(type.stem): t)
"""

        }

        lines.append("""
    default: return type
    }
}
""")

        return lines.joined(separator: "\n")
    }

    func visit() -> String {
        let lines: [String] = types().map { (type) in
            return """
open func visit(\(type.stem) type: \(type.typeName)) -> (any SType)? { nil }
"""

        }
        return lines.joined(separator: "\n")
    }

    func visitImpl() -> String {
        var lines: [String] = []

        lines += types().map { visitImpl(type: $0) }

        return lines.joined(separator: "\n\n")
    }

    func visitImpl(type: Node) -> String {
        var lines: [String] = []

        lines.append("""
private func visitImpl(\(type.stem) type: \(type.typeName)) -> any SType {
    if let t = visit(\(type.stem): type) { return t }
""")

        if !type.children.isEmpty {
            lines.append("""
    var type = type
""")
        }

        for child in type.children {
            lines.append("""
    type.\(child) = walk(type.\(child))
""")
        }

        lines.append("""
    return type
}
""")

        return lines.joined(separator: "\n")
    }
}
