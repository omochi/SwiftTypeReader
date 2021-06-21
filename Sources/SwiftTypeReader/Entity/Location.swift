public struct Location: Equatable, CustomStringConvertible {
    public init(_ elements: [LocationElement]) {
        self.elements = elements
    }

    public var elements: [LocationElement]

    public var description: String {
        elements.map { $0.description }.joined(separator: " -> ")
    }

    public func appending(_ element: LocationElement) -> Location {
        var elements = elements
        elements.append(element)
        return Location(elements)
    }

    public func deletingLast() -> Location {
        if elements.isEmpty { return self }

        var elements = elements
        elements.removeLast()
        return Location(elements)
    }
}

public enum LocationElement: Equatable, CustomStringConvertible {
    case module(name: String)
    case type(name: String)
    case genericParameter(index: Int)

    public var description: String {
        switch self {
        case .module(name: let name):
            return "module(name: \(name))"
        case .type(name: let name):
            return "type(name: \(name))"
        case .genericParameter(index: let index):
            return "genericParameter(index: \(index))"
        }
    }
}
