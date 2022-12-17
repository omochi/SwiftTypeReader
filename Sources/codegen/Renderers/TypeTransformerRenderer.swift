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
}
