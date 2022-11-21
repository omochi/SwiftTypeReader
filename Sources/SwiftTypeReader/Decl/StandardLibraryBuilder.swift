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
        addStruct(name: "Float")
        addStruct(name: "Double")
        addStruct(name: "String")
        addEnum(name: "Optional", genericParams: ["Wrapped"])
        addStruct(name: "Array", genericParams: ["Element"])
        addStruct(name: "Dictionary", genericParams: ["Key", "Value"])

        addProtocol(name: "Encodable")
        addProtocol(name: "Decodable")
        addProtocol(name: "Codable")

        module.sources.append(source)

        return module
    }
}
