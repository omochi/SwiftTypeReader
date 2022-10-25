import Foundation

public struct TypeSpecifier: CustomStringConvertible {
    public struct Element: Hashable & CustomStringConvertible {
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
            genericArgumentSpecifiers: [TypeSpecifier] = []
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

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            let args = unresolvedGenericArguments.asSpecifiers()
            hasher.combine(args.count)
            for arg in args {
                for e in arg.elements {
                    hasher.combine(e)
                }
            }
        }

        public static func ==(a: Element, b: Element) -> Bool {
            guard a.name == b.name else { return false }

            let aArgs = a.unresolvedGenericArguments.asSpecifiers()
            let bArgs = b.unresolvedGenericArguments.asSpecifiers()

            guard aArgs.elementsEqual(bArgs, by: { (aArg, bArg) in
                aArg.elements == bArg.elements
            }) else { return false }

            return true
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

    public var description: String {
        return elements.map { $0.description }.joined(separator: ".")
    }

    public func resolve() throws -> SType {
        guard let module = self.module else {
            throw MessageError("no Module")
        }
        
        return try TypeResolver(module: module)(specifier: self)
    }
}
