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
    public var sources: [SourceFile] = []

    public var types: [SType] {
        sources.flatMap { $0.types }
    }

    public func asLocation() -> Location {
        Location(module: name)
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
        case .type(name: let name):
            return getType(name: name).map { .type($0) }
        case .genericParameter:
            return nil
        }
    }

    public func resolve(location: Location) -> Element? {
        LocationResolver(context: context)
            .resolve(module: self, location: location)
    }

    static func swiftStandardLibrary(context: Context) -> Module {
        var builder = StandardLibraryBuilder(context: context)
        return builder.build()
    }
}

private struct StandardLibraryBuilder {
    var module: Module
    var source: SourceFile

    var location: Location { module.asLocation() }

    init(context: Context) {
        module = Module(context: context, name: "Swift")
        source = SourceFile(file: URL(fileURLWithPath: "stdlib.swift"))
    }

    mutating func addStruct(name: String) {
        let t = StructType(
            module: module,
            file: nil,
            location: location,
            name: name
        )

        source.types.append(.struct(t))
    }

    mutating func addProtocol(name: String) {
        let t = ProtocolType(
            module: module,
            file: nil,
            location: location,
            name: name
        )

        source.types.append(.protocol(t))
    }

    mutating func build() -> Module {
        addStruct(name: "Void")
        addStruct(name: "Bool")
        addStruct(name: "Int")
        addStruct(name: "Float")
        addStruct(name: "Double")
        addStruct(name: "String")
        addStruct(name: "Optional")
        addStruct(name: "Array")
        addStruct(name: "Dictionary")

        addProtocol(name: "Encodable")
        addProtocol(name: "Decodable")
        addProtocol(name: "Codable")

        module.sources.append(source)

        return module
    }
}
