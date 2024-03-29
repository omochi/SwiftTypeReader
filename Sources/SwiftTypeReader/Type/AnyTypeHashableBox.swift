public struct AnyTypeHashableBox: HashableBoxProtocol {
    public init(_ value: any SType) {
        self.value = value
    }

    public var value: any SType

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
public typealias AnyTypeOptionalStorage = GenericHashableOptionalStorage<AnyTypeHashableBox>
public typealias AnyTypeArrayStorage = GenericHashableArrayStorage<AnyTypeHashableBox>
