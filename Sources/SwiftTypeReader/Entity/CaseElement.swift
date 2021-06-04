public struct CaseElement {
    public init(
        name: String,
        associatedValues: [AssociatedValue]
    ) {
        self.name = name
        self.associatedValues = associatedValues
    }

    public var name: String
    public var associatedValues: [AssociatedValue]
}
