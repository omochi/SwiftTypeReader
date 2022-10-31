/*
 TypeResolver concerns where specifier written.
 */
struct TypeResolver {
    var module: Module
    
    func callAsFunction(specifier: TypeSpecifier) -> SType {
        if let type = resolve(specifier: specifier) {
            return type
        }
        return .unresolved(specifier)
    }

    func resolve(specifier: TypeSpecifier) -> SType? {
        /*
         Find out specifier is absolute or relative
         */
        var specifier = specifier
        if let module = specifier.removeModuleElement() {
            // Absolute specifier
            return resolveOnModule(module, specifier: specifier, index: 0)
        }

        if let type = findFirstElementType(specifier: specifier) {
            return resolveOnType(type, specifier: specifier, index: 1)
        }

        return nil
    }

    private func resolveOnModule(_ module: Module, specifier: TypeSpecifier, index: Int) -> SType? {
        guard index < specifier.elements.count else {
            return nil
        }
        let spec = specifier.elements[index]
        guard var type = module.getType(name: spec.name) else {
            return nil
        }
        type = applyGenericArguments(type: type, specifier: spec)
        return resolveOnType(type, specifier: specifier, index: index + 1)
    }

    private func resolveOnType(_ type: SType, specifier: TypeSpecifier, index: Int) -> SType? {
        guard index < specifier.elements.count else {
            return type
        }
        let spec = specifier.elements[index]
        guard var type = type.get(name: spec.name) else {
            return nil
        }
        type = applyGenericArguments(type: type, specifier: spec)
        return resolveOnType(type, specifier: specifier, index: index + 1)
    }

    private func applyGenericArguments(type: SType, specifier: TypeSpecifier.Element) -> SType {
        var type = type

        let args = specifier.genericArgumentSpecifiers.map { (argSpec) in
            argSpec.resolve()
        }

        if !args.isEmpty {
            type = type.applyingGenericArguments(args)
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

    private func findFirstElementType(specifier: TypeSpecifier) -> SType? {
        guard let first = specifier.elements.first else {
            return nil
        }

        func findType(name: String) -> SType? {
            var location = specifier.location

            while true {
                if let type = getType(name: first.name, location: location) {
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

        if var type = findType(name: first.name) {
            type = applyGenericArguments(type: type, specifier: first)
            return type
        }

        return nil
    }

    private func getType(name: String, location: Location) -> SType? {
        guard let element = module.resolve(location: location) else {
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
