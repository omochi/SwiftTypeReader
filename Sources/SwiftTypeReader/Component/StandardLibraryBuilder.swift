import Foundation

struct StandardLibraryBuilder {
    var module: ModuleDecl
    var source: SourceFileDecl

    init(context: Context) {
        module = ModuleDecl(context: context, name: "Swift")
        source = SourceFileDecl(
            module: module,
            file: URL(fileURLWithPath: "stdlib.swift")
        )
    }

    mutating func addStruct(name: String, genericParams: [String] = []) {
        var decl = StructDecl(
            context: source,
            name: name
        )

        decl.genericParams.items = genericParams.map { (param) in
            GenericParamDecl(context: decl, name: param)
        }

        source.types.append(decl)
    }

    mutating func addEnum(name: String, genericParams: [String] = []) {
        var decl = EnumDecl(
            context: source,
            name: name
        )

        decl.genericParams.items = genericParams.map { (param) in
            GenericParamDecl(context: decl, name: param)
        }

        source.types.append(decl)
    }

    mutating func addProtocol(name: String) {
//        let t = ProtocolType(
//            module: module,
//            file: source.file,
//            location: location,
//            name: name
//        )
//
//        source.types.append(.protocol(t))
    }

    mutating func build() -> ModuleDecl {
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
