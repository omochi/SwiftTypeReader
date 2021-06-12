import Foundation

/*
 Protocol.
 Not exsitential container type.
 */
public struct ProtocolType: RegularTypeProtocol {
    public init(
        module: Module?,
        file: URL?,
        name: String
    ) {
        self.module = module
        self.file = file
        self.name = name
    }

    public weak var module: Module?
    public var file: URL?
    public var name: String

    public var genericArgumentSpecifiers: [TypeSpecifier] {
        []
    }

}
