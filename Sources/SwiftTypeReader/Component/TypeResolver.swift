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
        guard let first = specifier.elements.first else {
            throw MessageError("broken specifier: \(specifier)")
        }

        /*
         Find out specifier is absolute or relative
         */
        if let element = module.get(name: first.name),
           case .module(let module) = element
        {
            // Absolute specifier
            return try resolveOnModule(module, specifier: specifier, index: 1)
        }

        if var type = try findType(name: first.name, location: specifier.location) {
            type = try applyGenericArguments(type: type, specifier: first)
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
        var elements: [LocationElement] = [
            .module(name: module.name)
        ]

        for spec in specifier.elements {
            // FIXME: generic arguments
            elements.append(.type(name: spec.name))
        }

        return Location(elements)
    }

    private func findType(name: String, location: Location) throws -> SType? {
        var location = location

        while true {
            if location.elements.isEmpty {
                break
            }

            if let type = try getType(name: name, location: location) {
                return type
            }

            location = location.deletingLast()
        }

        /*
         Find from top level of other modules
         */
        for module in module.otherModules {
            if let type = module.getType(name: name) {
                return type
            }
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
