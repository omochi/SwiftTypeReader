struct TypeResolver {
    func callAsFunction(module: Module, specifier: TypeSpecifier) throws -> SType {
        try resolveType(module: module, specifier: specifier)
    }

    func resolveType(module: Module, specifier: TypeSpecifier) throws -> SType {
        guard var type = try findType(
                module: module,
                name: specifier.name,
                location: specifier.location
        ) else {
            return .unresolved(specifier)
        }

        let args = try specifier.genericArgumentSpecifiers.compactMap { (argSpec) in
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

        if let swiftModule = module.modules?.swift,
           let t = try findTypeInModule(
            module: swiftModule,
            name: name,
            location: swiftModule.asLocation()
           ) {
            return t
        }

        return nil
    }

    func findTypeInModule(module: Module, name: String, location: Location) throws -> SType? {
        try ModuleTypeFinder(module: module)(name: name, location: location)
    }
}
