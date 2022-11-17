public struct AnyDeclContextHashableBox: HashableBoxProtocol {
    public init(_ value: any DeclContext) {
        self.value = value
    }

    public var value: any DeclContext

    public static func == (lhs: AnyDeclContextHashableBox, rhs: AnyDeclContextHashableBox) -> Bool {
        AnyKey(lhs.value) == AnyKey(rhs.value)
    }

    public func hash(into hasher: inout Hasher) {
        AnyKey(value).hash(into: &hasher)
    }
}

public typealias AnyDeclContextStorage = GenericHashableStorage<AnyDeclContextHashableBox>
