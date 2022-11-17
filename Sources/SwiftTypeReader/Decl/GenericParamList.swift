public struct GenericParamList {
    public init(_ items: [GenericParamDecl] = []) {
        self.items = items
    }

    public var items: [GenericParamDecl]
}
