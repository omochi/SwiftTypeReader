@propertyWrapper
public struct GenericHashableStorage<Box>: Hashable where
    Box: HashableBoxProtocol
{
    public init(_ wrappedValue: Box.Value) {
        self.init(wrappedValue: wrappedValue)
    }

    public init(wrappedValue: Box.Value) {
        self.storage = Box(wrappedValue)
    }

    public var wrappedValue: Box.Value {
        get { storage.value }
        set { storage = Box(newValue) }
    }

    private var storage: Box
}

@propertyWrapper
public struct GenericHashableOptionalStorage<Box>: Hashable where
    Box: HashableBoxProtocol
{
    public init(_ wrappedValue: Box.Value?) {
        self.init(wrappedValue: wrappedValue)
    }

    public init(wrappedValue: Box.Value?) {
        self.storage = wrappedValue.map { Box($0) }
    }

    public var wrappedValue: Box.Value? {
        get { storage?.value }
        set { storage = newValue.map { Box($0) }}
    }

    private var storage: Box?
}

@propertyWrapper
public struct GenericHashableArrayStorage<Box>: Hashable where
    Box: HashableBoxProtocol
{
    public init(_ wrappedValue: [Box.Value]) {
        self.init(wrappedValue: wrappedValue)
    }

    public init(wrappedValue: [Box.Value]) {
        self.wrappedValue = wrappedValue
    }

    public var wrappedValue: [Box.Value]

    public static func == (lhs: GenericHashableArrayStorage<Box>, rhs: GenericHashableArrayStorage<Box>) -> Bool {
        let lhs = lhs.wrappedValue
        let rhs = rhs.wrappedValue

        return lhs.elementsEqual(rhs) { (lhs, rhs) in
            Box(lhs) == Box(rhs)
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue.count)
        for item in wrappedValue {
            hasher.combine(Box(item))
        }
    }
}
