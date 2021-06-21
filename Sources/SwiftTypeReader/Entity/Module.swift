import Foundation

public final class Module {
    public init(
        modules: Modules?,
        name: String
    ) {
        self.modules = modules
        self.name = name
    }

    public weak var modules: Modules?
    public var name: String
    public var types: [SType] = []

    public func asLocation() -> Location {
        Location([.module(name: name)])
    }

    public func resolve(location: Location) throws -> Element? {
        try LocationResolver().resolve(module: self, location: location)
    }

    public func resolveType(specifier: TypeSpecifier) throws -> SType {
        try TypeResolver()(module: self, specifier: specifier)
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
            location: asLocation(),
            name: name
        )

        types.append(.struct(t))
    }

    func addProtocol(name: String) {
        let t = ProtocolType(
            module: self,
            file: nil,
            location: asLocation(),
            name: name
        )

        types.append(.protocol(t))
    }
}
