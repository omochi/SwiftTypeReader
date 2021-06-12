import Foundation

public final class Module {
    public init(
        modules: Modules?,
        name: String?
    ) {
        self.modules = modules
        self.name = name
    }

    public weak var modules: Modules?
    public var name: String?
    public var types: [SType] = []

    public func resolveType(specifier: TypeSpecifier) throws -> SType {
        guard var type = findType(name: specifier.name) else {
            return .unresolved(specifier)
        }

        let args = try specifier.genericArguments.compactMap { (argSpec) in
            try resolveType(specifier: argSpec)
        }

        if !args.isEmpty {
            type = try type.applyingGenericArguments(args)
        }

        return type
    }

    private func findType(name: String) -> SType? {
        if let t = findTypeLocal(name: name) {
            return t
        }

        if let m = modules?.swift,
           let t = m.findTypeLocal(name: name)
        {
            return t
        }

        return nil
    }

    private func findTypeLocal(name: String) -> SType? {
        types.first { (type) in
            type.name == name
        }
    }

    static func buildSwift(modules: Modules) -> Module {
        let m = Module(
            modules: modules,
            name: "Swift"
        )

        m.addStruct(name: "Void")
        m.addStruct(name: "Bool")
        m.addStruct(name: "Int")
        m.addStruct(name: "Float")
        m.addStruct(name: "Double")
        m.addStruct(name: "String")
        m.addStruct(name: "Optional")
        m.addStruct(name: "Array")
        m.addStruct(name: "Dictionary")

        m.addProtocol(name: "Encodable")
        m.addProtocol(name: "Decodable")
        m.addProtocol(name: "Codable")

        return m
    }

    func addStruct(name: String) {
        let t = StructType(
            module: self,
            file: nil,
            name: name
        )

        types.append(.struct(t))
    }

    func addProtocol(name: String) {
        let t = ProtocolType(
            module: self,
            file: nil,
            name: name
        )

        types.append(.protocol(t))
    }
}
