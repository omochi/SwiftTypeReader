/*
 To avoid ambiguity with `Type` keyword for metatype,
 name this type to SType.

 S means Swift.
 */
public protocol SType2: Hashable & CustomStringConvertible {}

extension SType2 {
    func asAnyType() -> AnyType {
        AnyType(self)
    }
}
