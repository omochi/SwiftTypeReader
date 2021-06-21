struct LocationResolver {
    func resolve(modules: Modules, location: Location) throws -> Element? {
        guard let first = location.elements.first,
              case .module(let name) = first else
        {
            throw MessageError("broken location: \(location)")
        }

        guard let module = (modules.modules.first { $0.name == name }) else { return nil }

        return try resolve(module: module, location: location, index: 1)
    }

    func resolve(module: Module, location: Location) throws -> Element? {
        // short cut
        if let first = location.elements.first,
              case .module(let name) = first,
              name == module.name
        {
            return try resolve(module: module, location: location, index: 1)
        }

        guard let modules = module.modules else { return nil }
        return try resolve(modules: modules, location: location)
    }

    private func resolve(module: Module, location: Location, index: Int) throws -> Element? {
        guard index < location.elements.count else {
            return .module(module)
        }

        switch location.elements[index] {
        case .type(name: let name):
            guard let type = (module.types.first { $0.name == name }) else {
                return nil
            }

            return .type(type)
        case .module, .genericParameter:
            throw MessageError("broken location: \(location)")
        }
    }

    private func resolve(type: SType, location: Location, index: Int) throws -> Element? {
        guard index < location.elements.count else {
            return .type(type)
        }

        switch location.elements[index] {
        case .type:
            // TODO: inner type
            return nil
        case .genericParameter(let gi):
            guard let type = type.regular else { return nil }

            guard gi < type.genericParameters.count else {
                throw MessageError("broken location: \(location)")
            }

            return try resolve(
                genericParameter: type.genericParameters[gi],
                location: location, index: index + 1
            )
        case .module:
            throw MessageError("broken location: \(location)")
        }
    }

    private func resolve(genericParameter: GenericParameterType, location: Location, index: Int) throws -> Element? {
        guard index < location.elements.count else {
            return .type(.genericParameter(genericParameter))
        }

        switch location.elements[index] {
        case .type:
            // TODO: type name dot expression
            return nil
        case .genericParameter, .module:
            throw MessageError("broken location: \(location)")
        }
    }
}
