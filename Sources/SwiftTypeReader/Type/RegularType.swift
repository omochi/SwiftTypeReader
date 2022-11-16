import Foundation

public enum RegularType: RegularTypeProtocol {
    case `struct`(StructType)
    case `enum`(EnumType)
    case `protocol`(ProtocolType)
    case `genericParameter`(GenericParameterType)

    public var `struct`: StructType? {
        guard case .struct(let t) = self else {
            return nil
        }
        return t
    }

    public var `enum`: EnumType? {
        guard case .enum(let t) = self else {
            return nil
        }
        return t
    }

    public var `protocol`: ProtocolType? {
        guard case .protocol(let t) = self else {
            return nil
        }
        return t
    }

    public var `genericParameter`: GenericParameterType? {
        guard case .genericParameter(let t) = self else {
            return nil
        }
        return t
    }

    var inner: RegularTypeProtocol {
        switch self {
        case .struct(let t): return t
        case .enum(let t): return t
        case .protocol(let t): return t
        case .genericParameter(let t): return t
        }
    }

    public var module: Module { inner.module }
    public var file: URL { inner.file }
    public var location: Location { inner.location }
    public var name: String { inner.name }
    public var genericParameters: [GenericParameterType] { inner.genericParameters }
    public var genericArgumentSpecifiers: [TypeSpecifier] { inner.genericArgumentSpecifiers }
    public func genericArguments() -> [SType] { inner.genericArguments() }
    public func inheritedTypes() -> [SType] { inner.inheritedTypes() }
    public var description: String { inner.description }
    public func asSpecifier() -> TypeSpecifier { inner.asSpecifier() }
    public var types: [SType] {
        switch self {
        case .struct(let t): return t.types
        case .enum(let t): return t.types
        case .protocol: return []
        case .genericParameter: return []
        }
    }

    public func applyingGenericArguments(_ args: [SType]) -> RegularType {
        switch self {
        case .struct(var t):
            t.setGenericArguments(args)
            return .struct(t)
        case .enum(var t):
            t.setGenericArguments(args)
            return .enum(t)
        case .protocol,
                .genericParameter:
            return self
        }
    }
}

public protocol RegularTypeProtocol: CustomStringConvertible {
    var module: Module { get }
    var file: URL { get }
    var location: Location { get }
    var name: String { get }
    var genericParameters: [GenericParameterType] { get }
    var genericArgumentSpecifiers: [TypeSpecifier] { get }
    var types: [SType] { get }
    func genericArguments() -> [SType]
    func inheritedTypes() -> [SType]
    func get(name: String) -> SType?
    func asSpecifier() -> TypeSpecifier
}

extension RegularTypeProtocol {
    public func get(name: String) -> SType? {
        if let type = genericParameters.first(where: { $0.name == name }) {
            return .genericParameter(type)
        }

        if let type = types.first(where: { $0.name == name }) {
            return type
        }

        return nil
    }

    public func asSpecifier() -> TypeSpecifier {
        var elements: [TypeSpecifier.Element] = [
            .init(name: location.module)
        ]

        for element in location.elements {
            switch element {
            case .type(name: let name):
                elements.append(.init(name: name))
            case .genericParameter:
                // invalid location
                break
            }
        }

        elements.append(
            .init(
                name: name,
                genericArgumentSpecifiers: genericArgumentSpecifiers
            )
        )

        return TypeSpecifier(
            module: module,
            file: file,
            location: location,
            elements: elements
        )
    }

    public var description: String {
        asSpecifier().description
    }
}


