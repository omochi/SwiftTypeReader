/*
 TypeResolver concerns where specifier written.
 */
struct TypeResolver {
    var module: Module
    
    func callAsFunction(specifier: TypeSpecifier) throws -> SType {
        if let type = try resolve(specifier: specifier) {
            return type
        }
        return .unresolved(specifier)
    }

    func resolve(specifier: TypeSpecifier) throws -> SType? {
        /*
         Find out specifier is absolute or relative
         */
        var specifier = specifier
        if let module = specifier.removeModuleElement() {
            // Absolute specifier
            return try resolveOnModule(module, specifier: specifier, index: 0)
        }

        if let type = try findFirstElementType(specifier: specifier) {
            return try resolveOnType(type, specifier: specifier, index: 1)
        }

        return nil
    }

    private func resolveOnModule(_ module: Module, specifier: TypeSpecifier, index: Int) throws -> SType? {
        guard index < specifier.elements.count else {
            throw MessageError("broken specifier: \(specifier)")
        }
        let spec = specifier.elements[index]
        guard var type = module.getType(name: spec.name) else {
            return nil
        }
        type = try applyGenericArguments(type: type, specifier: spec)
        return try resolveOnType(type, specifier: specifier, index: index + 1)
    }

    private func resolveOnType(_ type: SType, specifier: TypeSpecifier, index: Int) throws -> SType? {
        guard index < specifier.elements.count else {
            return type
        }
        let spec = specifier.elements[index]
        guard var type = type.get(name: spec.name) else {
            return nil
        }
        type = try applyGenericArguments(type: type, specifier: spec)
        return try resolveOnType(type, specifier: specifier, index: index + 1)
    }

    private func applyGenericArguments(type: SType, specifier: TypeSpecifier.Element) throws -> SType {
        var type = type

        let args = try specifier.genericArgumentSpecifiers.map { (argSpec) in
            try argSpec.resolve()
        }

        if !args.isEmpty {
            type = try type.applyingGenericArguments(args)
        }

        return type
    }

    private func location(module: Module, specifier: TypeSpecifier) -> Location {
        var elements: [LocationElement] = []

        for spec in specifier.elements {
            // FIXME: generic arguments
            elements.append(.type(name: spec.name))
        }

        return Location(module: module.name, elements: elements)
    }

    private func findFirstElementType(specifier: TypeSpecifier) throws -> SType? {
        guard let first = specifier.elements.first else {
            return nil
        }

        func findType(name: String) throws -> SType? {
            var location = specifier.location

            while true {
                if let type = try getType(name: first.name, location: location) {
                    return type
                }

                if location.elements.isEmpty {
                    break
                }

                location.removeLast()
            }

            /*
             Find from top level of other modules
             */
            for module in module.otherModules {
                if let type = module.getType(name: first.name) {
                    return type
                }
            }

            return nil
        }

        if var type = try findType(name: first.name) {
            type = try applyGenericArguments(type: type, specifier: first)
            return type
        }

        return nil
    }

    private func getType(name: String, location: Location) throws -> SType? {
        guard let element = try module.resolve(location: location) else {
            return nil
        }

        switch element {
        case .module(let module):
            return module.getType(name: name)
        case .type(let type):
            return type.get(name: name)
        }
    }
}
