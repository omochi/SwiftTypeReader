public struct AnyTypeHashableBox: HashableBoxProtocol {
    public init(_ value: any SType2) {
        self.value = value
    }

    public var value: any SType2

    public static func == (lhs: AnyTypeHashableBox, rhs: AnyTypeHashableBox) -> Bool {
        AnyKey(lhs.value) == AnyKey(rhs.value)
    }

    public func hash(into hasher: inout Hasher) {
        AnyKey(value).hash(into: &hasher)
    }

    public var description: String {
        value.description
    }
}

public typealias AnyTypeStorage = GenericHashableStorage<AnyTypeHashableBox>
