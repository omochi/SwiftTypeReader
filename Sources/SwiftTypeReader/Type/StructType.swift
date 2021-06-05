import Foundation

public struct StructType {
    public init(
        file: URL? = nil,
        name: String,
        genericsArguments: [Type] = [],
        storedProperties: [StoredProperty] = []
    ) {
        self.file = file
        self.name = name
        self.genericsArguments = genericsArguments
        self.storedProperties = storedProperties
    }

    public var file: URL?
    public var name: String
    public var genericsArguments: [Type]
    public var storedProperties: [StoredProperty]
}
