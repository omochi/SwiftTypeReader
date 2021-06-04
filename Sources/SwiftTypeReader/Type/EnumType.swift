public struct EnumType {
    public init(
        name: String,
        genericsArguments: [Type] = [],
        caseElements: [CaseElement] = []
    ) {
        self.name = name
        self.genericsArguments = genericsArguments
        self.caseElements = caseElements
    }

    public var name: String
    public var genericsArguments: [Type]
    public var caseElements: [CaseElement]
}
