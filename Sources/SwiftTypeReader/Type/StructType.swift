import Foundation

public struct StructType {
    public init(
        file: URL? = nil,
        name: String,
        genericsArguments: [SType] = [],
        storedProperties: [StoredProperty] = []
    ) {
        self.file = file
        self.name = name
        self.genericsArguments = genericsArguments
        self.storedProperties = storedProperties
    }

    public var file: URL?
    public var name: String
    public var genericsArguments: [SType]
    public var storedProperties: [StoredProperty]
}
