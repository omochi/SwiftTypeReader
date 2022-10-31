public final class Context {
    public var modules: [Module]

    public init() {
        self.modules = []

        modules.append(
            .swiftStandardLibrary(context: self)
        )
    }

    public func getModule(name: String) -> Module? {
        modules.first { $0.name == name }
    }

    public func getOrCreateModule(name: String) -> Module {
        if let module = getModule(name: name) {
            return module
        }

        let module = Module(context: self, name: name)
        modules.append(module)
        return module
    }

    public func resolve(location: Location) throws -> Element? {
        return try LocationResolver(context: self)
            .resolve(module: nil, location: location)
    }

}
