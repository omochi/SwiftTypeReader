public struct TypeSpecifier: CustomStringConvertible {
    public init(name: String, genericArguments: [TypeSpecifier]) {
        self.name = name
        self.genericArguments = genericArguments
    }

    public var name: String
    public var genericArguments: [TypeSpecifier]

    public var description: String {
        var str = name
        if !genericArguments.isEmpty {
            str += "<"
            str += genericArguments.map { $0.description }
                .joined(separator: ", ")
            str += ">"
        }
        return str
    }
}
