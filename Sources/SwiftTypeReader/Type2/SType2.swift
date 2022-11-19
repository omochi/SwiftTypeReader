/*
 To avoid ambiguity with `Type` keyword for metatype,
 name this type to SType.

 S means Swift.
 */
public protocol SType2: Hashable & CustomStringConvertible {
}

extension SType2 {
    public func toTypeRepr(
        containsModule: Bool
    ) -> any TypeRepr {
        return TypeToTypeReprImpl(
            type: self,
            containsModule: containsModule
        ).convert()
    }
}
