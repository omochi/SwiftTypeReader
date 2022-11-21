public protocol HashableBoxProtocol: Hashable {
    associatedtype Value

    init(_ value: Value)

    var value: Value { get }
}
