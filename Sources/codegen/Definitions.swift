struct Node {
    enum Kind: String, CaseIterable {
        case decl
        case type
        case typeRepr

        // special handling
        case declContext
    }

    enum Attribute {
        case `protocol`
        case declContext
    }

    init(
        _ kind: Kind,
        _ stem: String,
        _ parent: String? = nil,
        typeName: String? = nil,
        attributes: Set<Attribute> = [],
        children: [String] = []
    ) {
        self.kind = kind
        self.stem = stem
        self.parent = parent
        self.typeName = typeName ?? Self.defaultTypeName(
            kind: kind, stem: stem, isProtocol: attributes.contains(.protocol)
        )
        self.attributes = attributes
        self.children = children
    }

    var kind: Kind
    var stem: String
    var parent: String?
    var typeName: String
    var attributes: Set<Attribute>
    var children: [String]

    var optionalTypeName: String {
        if attributes.contains(.protocol) {
            return "(" + typeName + ")?"
        } else {
            return typeName + "?"
        }
    }

    static func defaultTypeName(kind: Kind, stem: String, isProtocol: Bool) -> String {
        var name = stem.pascal + kind.rawValue.pascal
        if isProtocol {
            name = "any " + name
        }
        return name
    }
}

struct Definitions {
    var nodes: [Node] = [
        .init(.decl, "accessor", "value"),
        .init(.decl, "associatedType", "type"),
        .init(.decl, "class", "nominalType"),
        .init(.decl, "enumCaseElement", "value", attributes: [.declContext]),
        .init(.decl, "enum", "nominalType"),
        .init(.decl, "func", "value", attributes: [.declContext]),
        .init(.declContext, "genericContext", typeName: "any GenericContext", attributes: [.protocol]),
        .init(.decl, "genericParam", "type"),
        .init(.decl, "genericType", "type", attributes: [.protocol, .declContext]),
        .init(.decl, "import"),
        .init(.decl, "init", "value", attributes: [.declContext]),
        .init(.decl, "module", "type", typeName: "Module", attributes: [.declContext]),
        .init(.decl, "nominalType", "genericType", attributes: [.protocol]),
        .init(.decl, "param", "value"),
        .init(.decl, "protocol", "nominalType"),
        .init(.decl, "sourceFile", typeName: "SourceFile", attributes: [.declContext]),
        .init(.decl, "struct", "nominalType"),
        .init(.decl, "typeAlias", "genericType"),
        .init(.decl, "type", "value", attributes: [.protocol]),
        .init(.decl, "value", attributes: [.protocol]),
        .init(.decl, "var", "value"),
        .init(.type, "class", "nominal", children: [
            "parent", "genericArgs"
        ]),
        .init(.type, "dependentMember", children: [
            "base"
        ]),
        .init(.type, "enum", "nominal", children: [
            "parent", "genericArgs"
        ]),
        .init(.type, "error"),
        .init(.type, "function", children: [
            "params", "result"
        ]),
        .init(.type, "genericParam"),
        .init(.type, "metatype", children: [
            "instance"
        ]),
        .init(.type, "module"),
        .init(.type, "nominal", attributes: [.protocol]),
        .init(.type, "protocol", "nominal"),
        .init(.type, "struct", "nominal", children: [
            "parent", "genericArgs"
        ]),
        .init(.type, "typeAlias", children: [
            "parent", "genericArgs"
        ]),
        .init(.typeRepr, "error"),
        .init(.typeRepr, "function"),
        .init(.typeRepr, "ident"),
        .init(.typeRepr, "metatype"),
        .init(.typeRepr, "tuple"),
        .init(.typeRepr, "composition"),
    ]

    func nodes(kind: Node.Kind) -> [Node] {
        switch kind {
        case .decl, .type, .typeRepr:
            return nodes.filter { $0.kind == kind }
        case .declContext:
            return nodes.filter { isDeclContext(node: $0) }
        }
    }

    func parent(of node: Node) -> Node? {
        guard let stem = node.parent else { return nil }

        return nodes.first {
            $0.stem == stem && $0.kind == node.kind
        }
    }

    func isDeclContext(node: Node) -> Bool {
        var node = node
        while true {
            if node.kind == .declContext { return true }
            if node.attributes.contains(.declContext) { return true }
            guard let parent = self.parent(of: node) else { break }
            node = parent
        }
        return false
    }
}
