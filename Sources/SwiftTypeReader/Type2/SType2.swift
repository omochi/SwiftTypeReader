/*
 To avoid ambiguity with `Type` keyword for metatype,
 name this type to SType.

 S means Swift.
 */
public protocol SType2: Hashable & CustomStringConvertible {
}

extension SType2 {
    public var description: String {
        switch self {
        case let self as ErrorType:
            return self.errorTypeDescription
        default:
            return toTypeRepr(containsModule: false).description
        }
    }

    public func toTypeRepr(
        containsModule: Bool
    ) -> any TypeRepr {
        do {
            return try TypeToTypeReprImpl(
                type: self,
                containsModule: containsModule
            ).convert()
        } catch {
            return ErrorTypeRepr(text: "\(error)")
        }
    }
}
