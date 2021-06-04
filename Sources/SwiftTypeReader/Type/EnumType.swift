public struct EnumType {
    public init(
        name: String,
        genericsArguments: [Type]
    ) {
        self.name = name
        self.genericsArguments = genericsArguments
    }

    public var name: String
    public var genericsArguments: [Type]
}
