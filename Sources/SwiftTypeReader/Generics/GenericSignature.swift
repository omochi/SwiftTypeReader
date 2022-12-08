public struct GenericSignature: Hashable & CustomStringConvertible {
    public init(
        params: [GenericParamType] = []
    ) {
        self.params = params
    }

    public var params: [GenericParamType]

    public var isEmpty: Bool { params.isEmpty }

    public var description: String {
        return Printer.genericClause(params.map { $0.name })
    }
}
