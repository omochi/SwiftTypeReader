import SwiftSyntax

struct AttributeReader {
    var attributes: [Attribute] = []

    mutating func read(list: AttributeListSyntax) {
        for element in list {
            guard case .attribute(let attributeSyntax) = element else {
                continue
            }

            attributes.append(.init(
                name: attributeSyntax.attributeName.trimmedDescription
            ))
        }
    }
}
