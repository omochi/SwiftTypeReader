import Foundation

public final class Module {
    public init(
        context: Context,
        name: String
    ) {
        self.context = context
        self.name = name
    }

    public unowned let context: Context
    public var name: String
    public var types: [SType] = []

    public func asLocation() -> Location {
        Location([.module(name: name)])
    }

    public var modulesForFind: [Module] {
        return [self] + otherModules
    }

    public var otherModules: [Module] {
        return context.modules.filter { $0 !== self }
    }

    public func getModule(name: String) -> Module? {
        return modulesForFind.first { $0.name == name }
    }

    public func getType(name: String) -> SType? {
        return types.first { $0.name == name }
    }

    public func get(name: String) -> Element? {
        /*
         Type shadows name of module itself
         */
        if let type = getType(name: name) {
            return .type(type)
        }

        if let module = getModule(name: name) {
            return .module(module)
        }

        return nil
    }

    public func get(element: LocationElement) -> Element? {
        switch element {
        case .module(name: let name):
            return getModule(name: name).map { .module($0) }
        case .type(name: let name):
            return getType(name: name).map { .type($0) }
        case .genericParameter:
            return nil
        }
    }

    public func resolve(location: Location) throws -> Element? {
        try LocationResolver(context: context)
            .resolve(module: self, location: location)
    }

    static func swiftStandardLibrary(context: Context) -> Module {
        let m = Module(
            context: context,
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
