/*
 Resolve complete location into concrete element
 */
struct LocationResolver {
    func resolve(modules: Modules, location: Location) throws -> Element? {
        return try resolve(
            modules: modules.modules,
            location: location
        )
    }

    func resolve(module: Module, location: Location) throws -> Element? {
        return try resolve(
            modules: module.modulesForFind,
            location: location
        )
    }

    private func resolve(modules: [Module], location: Location) throws -> Element? {
        guard let first = location.elements.first,
              case .module(let name) = first else
        {
            throw MessageError("broken location: \(location)")
        }

        guard let module = modules.first(where: { $0.name == name }) else {
            return nil
        }

        return try resolve(module: module, location: location, index: 1)
    }

    private func resolve(element: Element, location: Location, index: Int) throws -> Element? {
        switch element {
        case .module(let module):
            return try resolve(module: module, location: location, index: index)
        case .type(let type):
            return try resolve(type: type, location: location, index: index)
        }
    }

    private func resolve(module: Module, location: Location, index: Int) throws -> Element? {
        guard index < location.elements.count else {
            return .module(module)
        }
        guard let element = module.get(element: location.elements[index]) else {
            return nil
        }
        return try resolve(element: element, location: location, index: index + 1)
    }

    private func resolve(type: SType, location: Location, index: Int) throws -> Element? {
        guard index < location.elements.count else {
            return .type(type)
        }

        switch location.elements[index] {
        case .type(let name):
            guard let type = type.regular else { return nil }

            guard let nestedType = type.types.first(where: { $0.name == name }) else {
                return nil
            }

            return try resolve(
                type: nestedType,
                location: location,
                index: index + 1
            )
        case .genericParameter(let gi):
            guard let type = type.regular else { return nil }

            guard gi < type.genericParameters.count else {
                throw MessageError("broken location: \(location)")
            }

            return try resolve(
                genericParameter: type.genericParameters[gi],
                location: location,
                index: index + 1
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
