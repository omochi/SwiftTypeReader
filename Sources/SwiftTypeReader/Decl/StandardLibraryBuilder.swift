import Foundation

struct StandardLibraryBuilder {
    var module: Module
    var source: SourceFile

    init(context: Context) {
        module = Module(context: context, name: "Swift")
        source = SourceFile(
            module: module,
            file: URL(fileURLWithPath: "stdlib.swift")
        )
    }

    mutating func addStruct(name: String, genericParams: [String] = []) {
        let decl = StructDecl(
            context: source,
            name: name
        )

        decl.syntaxGenericParams = GenericParamList(genericParams.map { (param) in
            GenericParamDecl(context: decl, name: param)
        })

        source.types.append(decl)
    }

    mutating func addEnum(name: String, genericParams: [String] = []) {
        let decl = EnumDecl(
            context: source,
            name: name
        )

        decl.syntaxGenericParams = GenericParamList(genericParams.map { (param) in
            GenericParamDecl(context: decl, name: param)
        })

        source.types.append(decl)
    }

    mutating func addProtocol(name: String) {
        let decl = ProtocolDecl(
            context: source,
            name: name
        )

        source.types.append(decl)
    }

    mutating func build() -> Module {
        addStruct(name: "Void")
        addStruct(name: "Bool")
        addStruct(name: "Int")
        addStruct(name: "Int8")
        addStruct(name: "Int16")
        addStruct(name: "Int32")
        addStruct(name: "Int64")
        addStruct(name: "UInt8")
        addStruct(name: "UInt16")
        addStruct(name: "UInt32")
        addStruct(name: "UInt64")
        addStruct(name: "Float")
        addStruct(name: "Float32")
        addStruct(name: "Float64")
        addStruct(name: "Double")
        addStruct(name: "Character")
        addStruct(name: "String")
        addEnum(name: "Optional", genericParams: ["Wrapped"])
        addStruct(name: "Array", genericParams: ["Element"])
        addStruct(name: "Dictionary", genericParams: ["Key", "Value"])

        addProtocol(name: "Encodable")
        addProtocol(name: "Decodable")
        addProtocol(name: "Codable")
        addProtocol(name: "Sendable")
        addProtocol(name: "Hashable")
        addProtocol(name: "Equatable")
        addProtocol(name: "RawRepresentable")
        addProtocol(name: "Error")
        addProtocol(name: "Identifiable")

        module.sources.append(source)

        return module
    }
}
