public final class ErrorType: SType & HashableFromIdentity {
    public init(
        repr: (any TypeRepr)? = nil,
        error: Swift.Error? = nil
    ) {
        self.repr = repr
        self.error = error
    }

    public var repr: (any TypeRepr)?
    public var error: Swift.Error?

    public var errorTypeDescription: String {
        if let repr {
            return repr.description
        }

        var s = ""
        s += "(ERROR"
        if let error {
            s += ": \(error)"
        }
        s += ")"
        return s
    }
}
