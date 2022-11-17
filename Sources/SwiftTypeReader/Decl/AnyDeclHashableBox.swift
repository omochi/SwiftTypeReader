public struct AnyDeclHashableBox: HashableBoxProtocol {
    public init(_ value: any Decl) {
        self.value = value
    }

    public var value: any Decl

    public static func == (lhs: AnyDeclHashableBox, rhs: AnyDeclHashableBox) -> Bool {
        AnyKey(lhs.value) == AnyKey(rhs.value)
    }

    public func hash(into hasher: inout Hasher) {
        AnyKey(value).hash(into: &hasher)
    }
}

public typealias AnyDeclStorage = GenericHashableStorage<AnyDeclHashableBox>
