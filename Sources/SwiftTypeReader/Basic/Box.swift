import Foundation

public final class Box<T> {
    public let value: T

    public init(_ value: T) {
        self.value = value
    }
}

public final class MutableBox<T> {
    public var value: T

    public init(_ value: T) {
        self.value = value
    }
}
