/*
 Resolve complete location into concrete element
 */
struct LocationResolver {
    var context: Context

    func resolve(module: Module?, location: Location) -> Element? {
        return resolve(
            modules: module?.modulesForFind ?? context.modules,
            location: location
        )
    }

    private func resolve(modules: [Module], location: Location) -> Element? {
        guard let module = modules.first(where: { $0.name == location.module }) else {
            return nil
        }

        return resolve(module: module, location: location, index: 0)
    }

    private func resolve(element: Element, location: Location, index: Int) -> Element? {
        switch element {
        case .module(let module):
            return resolve(module: module, location: location, index: index)
        case .type(let type):
            return resolve(type: type, location: location, index: index)
        }
    }

    private func resolve(module: Module, location: Location, index: Int) -> Element? {
        guard index < location.elements.count else {
            return .module(module)
        }
        guard let element = module.get(element: location.elements[index]) else {
            return nil
        }
        return resolve(element: element, location: location, index: index + 1)
    }

    private func resolve(type: SType, location: Location, index: Int) -> Element? {
        guard index < location.elements.count else {
            return .type(type)
        }

        switch location.elements[index] {
        case .type(let name):
            guard let type = type.regular else { return nil }

            guard let nestedType = type.types.first(where: { $0.name == name }) else {
                return nil
            }

            return resolve(
                type: nestedType,
                location: location,
                index: index + 1
            )
        case .genericParameter(let gi):
            guard let type = type.regular,
                  gi < type.genericParameters.count else
            {
                return nil
            }

            return resolve(
                genericParameter: type.genericParameters[gi],
                location: location,
                index: index + 1
            )
        }
    }

    private func resolve(genericParameter: GenericParameterType, location: Location, index: Int) -> Element? {
        guard index < location.elements.count else {
            return .type(.genericParameter(genericParameter))
        }

        switch location.elements[index] {
        case .type:
            // TODO: type name dot expression
            return nil
        case .genericParameter:
            return nil
        }
    }
}
