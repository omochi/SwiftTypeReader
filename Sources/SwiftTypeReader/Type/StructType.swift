import Foundation

public struct StructType {
    public init(
        name: String,
        genericsArguments: [Type] = [],
        storedProperties: [StoredProperty] = []
    ) {
        self.name = name
        self.genericsArguments = genericsArguments
        self.storedProperties = storedProperties
    }

    public var name: String
    public var genericsArguments: [Type]
    public var storedProperties: [StoredProperty]
}
