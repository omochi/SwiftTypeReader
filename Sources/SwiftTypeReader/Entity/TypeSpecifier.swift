import Foundation

public struct TypeSpecifier: CustomStringConvertible {
    public struct Element: CustomStringConvertible {
        public var name: String
        public var unresolvedGenericArguments: TypeCollection

        public func genericArguments() throws -> [SType] {
            try unresolvedGenericArguments.resolved()
        }

        public var genericArgumentSpecifiers: [TypeSpecifier] {
            get {
                unresolvedGenericArguments.asSpecifiers()
            }
        }

        public init(
            name: String,
            genericArgumentSpecifiers: [TypeSpecifier]
        ) {
            self.name = name
            self.unresolvedGenericArguments = TypeCollection(genericArgumentSpecifiers)
        }

        public var description: String {
            var str = name
            if !genericArgumentSpecifiers.isEmpty {
                str += "<"
                str += genericArgumentSpecifiers.map { $0.description }
                    .joined(separator: ", ")
                str += ">"
            }
            return str
        }
    }

    public init(
        module: Module?,
        file: URL?,
        location: Location,
        elements: [Element]
    ) {
        precondition(!elements.isEmpty, "elements is empty")
        self.module = module
        self.file = file
        self.location = location
        self.elements = elements
    }

    public weak var module: Module?
    public var file: URL?
    public var location: Location
    public var elements: [Element]

    public var lastElement: Element { elements.last! }

//    public func genericArguments() throws -> [SType] {
//        try unresolvedGenericArguments.resolved()
//    }
//
//    public var genericArgumentSpecifiers: [TypeSpecifier] {
//        get {
//            unresolvedGenericArguments.asSpecifiers()
//        }
//        set {
//            unresolvedGenericArguments = TypeCollection(newValue)
//        }
//    }

    public var description: String {
        return elements.map { $0.description }.joined(separator: ".")
    }

    public func resolve() throws -> SType {
        guard let module = self.module else {
            throw MessageError("no Module")
        }

        return try module.resolveType(specifier: self)
    }
}
