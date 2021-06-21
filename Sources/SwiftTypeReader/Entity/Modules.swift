import Foundation

public final class Modules {
    public var modules: [Module] = []

    public init() {
        modules.append(.buildSwift(modules: self))
    }

    public var swift: Module? {
        modules.first { $0.name == "Swift" }
    }

    public func resolve(location: Location) throws -> Element? {
        try LocationResolver().resolve(modules: self, location: location)
    }
}
