import Foundation

public struct FunctionRequirement {
    public struct Parameter {
        public init(label: String?, name: String, type: TypeSpecifier) {
            self.label = label
            self.name = name
            self.unresolvedType = .unresolved(type)
        }

        public var label: String?
        public var name: String

        public func type() -> SType {
            unresolvedType.resolved()
        }
        public var unresolvedType: SType
    }

    public init(
        name: String,
        parameters: [Parameter],
        outputType: TypeSpecifier?,
        isStatic: Bool,
        isThrows: Bool,
        isRethrows: Bool,
        isAsync: Bool,
        isReasync: Bool
    ) {
        self.name = name
        self.parameters = parameters
        self.unresolvedOutputType = outputType.map(SType.unresolved(_:))
        self.isStatic = isStatic
        self.isThrows = isThrows
        self.isRethrows = isRethrows
        self.isAsync = isAsync
        self.isReasync = isReasync
    }

    public var name: String

    public var parameters: [Parameter]

    public func outputType() -> SType? {
        unresolvedOutputType?.resolved()
    }
    public var unresolvedOutputType: SType?

    public var isStatic: Bool
    public var isThrows: Bool
    public var isRethrows: Bool
    public var isAsync: Bool
    public var isReasync: Bool
}
