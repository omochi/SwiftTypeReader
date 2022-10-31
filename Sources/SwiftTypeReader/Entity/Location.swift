public struct Location: Hashable & CustomStringConvertible {
    public init(
        module: String,
        elements: [LocationElement] = []
    ) {
        self.module = module
        self.elements = elements
    }

    public var module: String
    public var elements: [LocationElement]

    public var description: String {
        var parts: [String] = ["module(\(module))"]
        parts += elements.map { $0.description }
        return parts.joined(separator: " -> ")
    }

    public mutating func append(_ element: LocationElement) {
        elements.append(element)
    }

    public func appending(_ element: LocationElement) -> Location {
        var copy = self
        copy.append(element)
        return copy
    }

    public mutating func removeLast() {
        elements.removeLast()
    }

    public func removingLast() -> Location {
        var copy = self
        copy.removeLast()
        return copy
    }
}

public enum LocationElement: Hashable & CustomStringConvertible {
    case type(name: String)
    case genericParameter(index: Int)

    public var description: String {
        switch self {
        case .type(name: let name):
            return "type(\(name))"
        case .genericParameter(index: let index):
            return "genericParameter(\(index))"
        }
    }
}
