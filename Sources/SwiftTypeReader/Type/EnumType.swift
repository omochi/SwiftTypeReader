import Foundation

public struct EnumType {
    public init(
        file: URL? = nil,
        name: String,
        genericsArguments: [Type] = [],
        caseElements: [CaseElement] = []
    ) {
        self.file = file
        self.name = name
        self.genericsArguments = genericsArguments
        self.caseElements = caseElements
    }

    public var file: URL?
    public var name: String
    public var genericsArguments: [Type]
    public var caseElements: [CaseElement]
}
