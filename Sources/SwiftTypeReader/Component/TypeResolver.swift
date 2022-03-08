struct TypeResolver {
    func callAsFunction(module: Module, specifier: TypeSpecifier) throws -> SType {
        try resolveType(module: module, specifier: specifier)
    }

    func resolveType(module: Module, specifier: TypeSpecifier) throws -> SType {
        // TODO
        let element = specifier.lastElement

        guard var type = try findType(
                module: module,
                name: element.name,
                location: specifier.location
        ) else {
            return .unresolved(specifier)
        }

        let args = try element.genericArgumentSpecifiers.compactMap { (argSpec) in
            try resolveType(module: module, specifier: argSpec)
        }

        if !args.isEmpty {
            type = try type.applyingGenericArguments(args)
        }

        return type
    }

    func findType(module: Module, name: String, location: Location) throws -> SType? {
        if let t = try findTypeInModule(
            module: module, name: name, location: location
        ) {
            return t
        }

        for module in (module.modules?.modules ?? []) {
            if let t = try findTypeInModule(
                module: module, name: name, location: module.asLocation()
            ) {
                return t 
            }
        }

        return nil
    }

    func findTypeInModule(module: Module, name: String, location: Location) throws -> SType? {
        try ModuleTypeFinder(module: module)(name: name, location: location)
    }
}
