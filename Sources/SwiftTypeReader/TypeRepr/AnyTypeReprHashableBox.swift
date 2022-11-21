public struct AnyTypeReprHashableBox: HashableBoxProtocol {
    public init(_ value: any TypeRepr) {
        self.value = value
    }

    public var value: any TypeRepr

    public static func == (lhs: AnyTypeReprHashableBox, rhs: AnyTypeReprHashableBox) -> Bool {
        AnyKey(lhs.value) == AnyKey(rhs.value)
    }

    public func hash(into hasher: inout Hasher) {
        AnyKey(value).hash(into: &hasher)
    }

    public var description: String {
        value.description
    }
}

public typealias AnyTypeReprStorage = GenericHashableStorage<AnyTypeReprHashableBox>
public typealias AnyTypeReprOptionalStorage = GenericHashableOptionalStorage<AnyTypeReprHashableBox>
public typealias AnyTypeReprArrayStorage = GenericHashableArrayStorage<AnyTypeReprHashableBox>
