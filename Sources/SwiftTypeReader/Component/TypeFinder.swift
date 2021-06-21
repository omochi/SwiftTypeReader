import Foundation

struct TypeFinder {
    var module: Modules

    func callAsFunction(name: String, location: Location) throws -> SType? {
        var location = location

        while true {
            if location.elements.isEmpty { return nil }

            if let type = try findSingle(name: name, location: location) {
                return type
            }

            location = location.deletingLast()
        }
    }

    func findSingle(name: String, location: Location) throws -> SType? {
        guard let ret = try module.resolve(location: location) else {
            return nil
        }

        switch ret {
        case .module(let module):
            if let type = (module.types.first { $0.name == name }) {
                return type
            }
        case .type(let type):
            guard let type = type.regular else { return nil }

            if let type = (type.genericParameters.first { $0.name == name }) {
                return .genericParameter(type)
            }
        }

        return nil
    }
}
