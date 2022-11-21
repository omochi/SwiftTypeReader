public enum FunctionAttribute: String, Hashable & CustomStringConvertible {
    case `throws`
    case `async`

    public var description: String { rawValue }
}

public enum FunctionParamAttribute: String, Hashable & CustomStringConvertible {
    case `inout`

    public var description: String { rawValue }
}

public struct FunctionType: SType {
    public struct Param: Hashable & CustomStringConvertible {
        public init(
            attributes: [FunctionParamAttribute],
            type: any SType
        ) {
            self.attributes = attributes
            self.type = type
        }

        // FIXME: unimplemented
        public var attributes: [FunctionParamAttribute]
        @AnyTypeStorage public var type: any SType

        public var description: String {
            var s = ""

            if attributes.contains(.inout) {
                s += "inout"
            }

            if !s.isEmpty {
                s += " "
            }

            s += type.description

            return s
        }
    }

    public init(
        attributes: [FunctionAttribute],
        params: [Param],
        result: any SType
    ) {
        self.attributes = attributes
        self.params = params
        self.result = result
    }

    public var attributes: [FunctionAttribute]
    public var params: [Param]
    @AnyTypeStorage public var result: any SType
}
