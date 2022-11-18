import XCTest
import SwiftTypeReader

final class SwiftTypeReaderTests: ReaderTestCaseBase {
    func testSimpleStruct() throws {
        let module = try read("""
struct S {
    var a: Int?
}
"""
        )

        let s = try XCTUnwrap(module.find(name: "S") as? StructDecl)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.moduleContext.name, "main")


        let a = try XCTUnwrap(s.find(name: "a") as? VarDecl)
        XCTAssertEqual(a.name, "a")

        XCTAssertEqual(s.storedProperties.count, 1)
        XCTAssertIdentical(s.storedProperties[safe: 0], a)

        let aType = try XCTUnwrap(a.interfaceType as? any NominalType)
        XCTAssertEqual(aType.description, "Optional<Int>")

        let aTypeDecl = aType.nominalTypeDecl

        XCTAssertEqual(aTypeDecl.moduleContext.name, "Swift")
        XCTAssertEqual(aTypeDecl.name, "Optional")
        XCTAssertEqual(aTypeDecl.declaredInterfaceType.description, "Optional<Wrapped>")

        XCTAssertEqual(aType.genericArgs.count, 1)

        let aWrappedType = try XCTUnwrap(aType.genericArgs[safe: 0] as? StructType2)
        XCTAssertEqual(aWrappedType.decl.moduleContext.name, "Swift")
        XCTAssertEqual(aWrappedType.decl.name, "Int")
    }

    func testTwoStruct() throws {
        let module = try read("""
struct S1 {
    var a: Int
    var b: S2
}

struct S2 {
    var a: Int
}
"""
        )

        do {
            let s1 = try XCTUnwrap(module.find(name: "S1") as? StructDecl)
            XCTAssertEqual(s1.name, "S1")

            let a = try XCTUnwrap(s1.find(name: "a") as? VarDecl)
            XCTAssertEqual(a.name, "a")
            XCTAssertEqual((a.interfaceType as? any NominalType)?.name, "Int")

            let b = try XCTUnwrap(s1.find(name: "b") as? VarDecl)
            XCTAssertEqual(b.name, "b")

            let s2 = try XCTUnwrap(b.interfaceType as? StructType2)
            XCTAssertEqual(s2.decl.name, "S2")
            XCTAssertEqual(s2.decl.storedProperties.count, 1)
        }

        do {
            let s2 = try XCTUnwrap(module.find(name: "S2") as? StructDecl)
            XCTAssertEqual(s2.name, "S2")

            let a = try XCTUnwrap(s2.find(name: "a") as? VarDecl)
            XCTAssertEqual(a.name, "a")
            XCTAssertEqual((a.interfaceType as? any NominalType)?.name, "Int")
        }

    }

    func testUnknown() throws {
        let module = try read("""
struct S {
    var a: URL
}
"""
        )

        let s = try XCTUnwrap(module.findType(name: "S") as? StructDecl)

        let a = try XCTUnwrap(s.find(name: "a") as? VarDecl)

        let aType = try XCTUnwrap(a.interfaceType as? UnknownType)
        XCTAssertEqual(aType.description, "URL")
    }

    func testEnum() throws {
        let module = try read("""
enum E {
    case a
    case b(Int)
    case c(x: Int, y: String)
}
"""
        )

        let e = try XCTUnwrap(module.find(name: "E") as? EnumDecl)
        XCTAssertEqual(e.caseElements.count, 3)

        do {
            let c = try XCTUnwrap(e.find(name: "a") as? EnumCaseElementDecl)
            XCTAssertIdentical(e.caseElements[safe: 0], c)
            XCTAssertEqual(c.name, "a")
            XCTAssertEqual(c.associatedValues.count, 0)
        }

        do {
            let c = try XCTUnwrap(e.find(name: "b") as? EnumCaseElementDecl)
            XCTAssertIdentical(e.caseElements[safe: 1], c)
            XCTAssertEqual(c.name, "b")

            XCTAssertEqual(c.associatedValues.count, 1)

            let v = try XCTUnwrap(c.associatedValues[safe: 0])
            XCTAssertNil(v.name)
            XCTAssertEqual((v.interfaceType as? any NominalType)?.name, "Int")
        }

        do {
            let c = try XCTUnwrap(e.find(name: "c") as? EnumCaseElementDecl)
            XCTAssertIdentical(e.caseElements[safe: 2], c)
            XCTAssertEqual(c.name, "c")

            XCTAssertEqual(c.associatedValues.count, 2)

            let x = try XCTUnwrap(c.find(name: "x") as? ParamDecl)
            XCTAssertIdentical(c.associatedValues[safe: 0], x)
            XCTAssertEqual(x.name, "x")
            XCTAssertEqual((x.interfaceType as? any NominalType)?.name, "Int")

            let y = try XCTUnwrap(c.find(name: "y") as? ParamDecl)
            XCTAssertIdentical(c.associatedValues[safe: 1], y)
            XCTAssertEqual(y.name, "y")
            XCTAssertEqual((y.interfaceType as? any NominalType)?.name, "String")
        }
    }
//
//    func testProtocol() throws {
//        let module = try read("""
//protocol P: Encodable {
//    associatedtype T: Decodable
//    var a: String { mutating get async throws }
//    func b(x: Int) async throws -> Double
//    static var c: Int { get nonmutating set }
//    static func d(_ x: Int, for y: Int)
//}
//""")
//        let p = try XCTUnwrap(module.types[safe: 0]?.protocol)
//
//        XCTAssertEqual(p.inheritedTypes().first?.name, "Encodable")
//        XCTAssertEqual(p.associatedTypes, ["T"])
//
//        do {
//            let a = try XCTUnwrap(p.propertyRequirements[safe: 0])
//            XCTAssertEqual(a.name, "a")
//            XCTAssertEqual(a.unresolvedType.name, "String")
//            XCTAssertEqual(a.accessors, [.get(mutating: true, async: true, throws: true)])
//            XCTAssertEqual(a.isStatic, false)
//        }
//
//        do {
//            let b = try XCTUnwrap(p.functionRequirements[safe: 0])
//            XCTAssertEqual(b.name, "b")
//            XCTAssertEqual(b.parameters.first?.label, nil)
//            XCTAssertEqual(b.parameters.first?.name, "x")
//            XCTAssertEqual(b.parameters.first?.unresolvedType.name, "Int")
//            XCTAssertEqual(b.unresolvedOutputType?.name, "Double")
//            XCTAssertEqual(b.isAsync, true)
//            XCTAssertEqual(b.isThrows, true)
//            XCTAssertEqual(b.isStatic, false)
//        }
//
//        do {
//            let c = try XCTUnwrap(p.propertyRequirements[safe: 1])
//            XCTAssertEqual(c.name, "c")
//            XCTAssertEqual(c.unresolvedType.name, "Int")
//            XCTAssertEqual(c.accessors, [.get(), .set(nonmutating: true)])
//            XCTAssertEqual(c.isStatic, true)
//        }
//
//        do {
//            let d = try XCTUnwrap(p.functionRequirements[safe: 1])
//            XCTAssertEqual(d.name, "d")
//            XCTAssertEqual(d.parameters.first?.label, "_")
//            XCTAssertEqual(d.parameters.first?.name, "x")
//            XCTAssertEqual(d.parameters.first?.unresolvedType.name, "Int")
//            XCTAssertEqual(d.parameters[safe: 1]?.label, "for")
//            XCTAssertEqual(d.parameters[safe: 1]?.name, "y")
//            XCTAssertEqual(d.parameters[safe: 1]?.unresolvedType.name, "Int")
//            XCTAssertEqual(d.unresolvedOutputType?.name, nil)
//            XCTAssertEqual(d.isAsync, false)
//            XCTAssertEqual(d.isThrows, false)
//            XCTAssertEqual(d.isStatic, true)
//        }
//    }
//
//    func testObservedStoredProperty() throws {
//        let module = try read("""
//struct S {
//    var a: Int { 0 }
//    var b: Int = 0 {
//        willSet {}
//        didSet {}
//    }
//    var c: Int {
//        get { 0 }
//    }
//"""
//        )
//
//        let s = try XCTUnwrap(module.types[safe: 0]?.struct)
//
//        XCTAssertEqual(s.storedProperties.count, 1)
//
//        let b = try XCTUnwrap(s.storedProperties[safe: 0])
//        XCTAssertEqual(b.name, "b")
//        XCTAssertEqual(b.type().name, "Int")
//    }
//
//    func testInheritanceClause() throws {
//        let module = try read("""
//enum E: Codable {
//    case a
//}
//""")
//        let e = try XCTUnwrap(module.types[safe: 0]?.enum)
//
//        XCTAssertEqual(e.inheritedTypes().count, 1)
//
//        let c = try XCTUnwrap(e.inheritedTypes()[safe: 0])
//        XCTAssertNotNil(c.protocol)
//        XCTAssertEqual(c.protocol?.module.name, "Swift")
//        XCTAssertEqual(c.name, "Codable")
//    }
//
//    func testGenericParameter() throws {
//        let module = try read("""
//struct S<T> {
//    var a: T
//}
//"""
//        )
//
//        let s = try XCTUnwrap(module.types[safe: 0]?.struct)
//        XCTAssertEqual(s.name, "S")
//
//        XCTAssertEqual(s.genericParameters.count, 1)
//        let t = try XCTUnwrap(s.genericParameters[safe: 0])
//        XCTAssertEqual(t.name, "T")
//
//        XCTAssertEqual(s.storedProperties.count, 1)
//        let a = try XCTUnwrap(s.storedProperties[safe: 0])
//        XCTAssertEqual(a.name, "a")
//
//        let at = try XCTUnwrap(a.type().genericParameter)
//        XCTAssertEqual(
//            at.location,
//            Location(module: "main", elements: [.type(name: "S")])
//        )
//    }
//
//    func testNestedTypeProperty() throws {
//        let module = try read("""
//struct S {
//    var x: A.B
//    var y: A.B.C
//}
//"""
//        )
//
//        let s = try XCTUnwrap(module.types[safe: 0]?.struct)
//        XCTAssertEqual(s.name, "S")
//
//        XCTAssertEqual(s.storedProperties.count, 2)
//
//        let x = try XCTUnwrap(s.storedProperties[safe: 0])
//        XCTAssertEqual(x.name, "x")
//        XCTAssertEqual(x.type().description, "A.B")
//
//        let y = try XCTUnwrap(s.storedProperties[safe: 1])
//        XCTAssertEqual(y.name, "y")
//        XCTAssertEqual(y.type().description, "A.B.C")
//    }
//
//    func testNestedTypeInStruct() throws {
//        let module = try read("""
//struct A {
//    struct B {}
//}
//"""
//        )
//
//        XCTAssertEqual(module.types.count, 1)
//        let a = try XCTUnwrap(module.types[safe: 0]?.struct)
//        XCTAssertEqual(a.name, "A")
//
//        XCTAssertEqual(a.types.count, 1)
//        let b = try XCTUnwrap(a.types[safe: 0]?.struct)
//        XCTAssertEqual(b.name, "B")
//        XCTAssertEqual(
//            b.location,
//            Location(module: "main", elements: [.type(name: "A")])
//        )
//    }
//
//    func testNestedTypeInEnum() throws {
//        let module = try read("""
//enum A {
//    struct B {}
//}
//"""
//        )
//
//        let a = try XCTUnwrap(module.types[safe: 0]?.enum)
//        XCTAssertEqual(a.name, "A")
//
//        let b = try XCTUnwrap(a.types[safe: 0]?.struct)
//        XCTAssertEqual(b.name, "B")
//        XCTAssertEqual(
//            b.location,
//            Location(module: "main", elements: [.type(name: "A")])
//        )
//    }
//
//    func testResolveNestedTypes() throws {
//        let module = try read("""
//struct A {
//    struct B {
//        var b1: Int = 0
//    }
//
//    var x: B
//}
//
//struct B {
//    var b2: Int = 0
//}
//
//struct C {
//    var y: B
//}
//""")
//        let a = try XCTUnwrap(module.getType(name: "A")?.struct)
//
//        let xb = try XCTUnwrap(a.storedProperties[safe: 0]?.type().struct)
//        XCTAssertEqual(xb.storedProperties[safe: 0]?.name, "b1")
//
//        let c = try XCTUnwrap(module.getType(name: "C")?.struct)
//
//        let yb = try XCTUnwrap(c.storedProperties[safe: 0]?.type().struct)
//        XCTAssertEqual(yb.storedProperties[safe: 0]?.name, "b2")
//    }
//
//    func testModules() throws {
//        _ = try Reader(
//            context: context,
//            module: context.getOrCreateModule(name: "MyLib")
//        ).read(
//            source: """
//public enum E {
//    case a
//}
//""",
//            file: URL(fileURLWithPath: "MyLib.swift")
//        )
//
//        let module = try Reader(
//            context: context
//        ).read(
//            source: """
//import MyLib
//
//protocol P {
//    func f() -> E
//}
//""",
//            file: URL(fileURLWithPath: "main.swift")
//        )
//
//        let p = try XCTUnwrap(module.types[safe: 0]?.protocol)
//        XCTAssertEqual(p.name, "P")
//        let f = try XCTUnwrap(p.functionRequirements[safe: 0])
//        XCTAssertEqual(f.name, "f")
//        let e = try XCTUnwrap(f.outputType()?.enum)
//        let c = try XCTUnwrap(e.caseElements[safe: 0])
//        XCTAssertEqual(c.name, "a")
//        XCTAssertEqual(module.imports[safe: 0]?.name, "MyLib")
//    }
//
//    func testImports() throws {
//        let source = try Reader(
//            context: context
//        ).read(
//            source: """
//import Foo
//@preconcurrency import Bar
//import struct Baz.S
//""",
//            file: URL(fileURLWithPath: "main.swift")
//        )
//
//        let i0 = try XCTUnwrap(source.imports[safe: 0])
//        XCTAssertEqual(i0.name, "Foo")
//        let i1 = try XCTUnwrap(source.imports[safe: 1])
//        XCTAssertEqual(i1.name, "Bar")
//        let i2 = try XCTUnwrap(source.imports[safe: 2])
//        XCTAssertEqual(i2.name, "Baz.S") // INFO: type importing is not supported yet. this should be treated as TypeSpecifier.
//        // INFO: importKind is not supported yet.
//    }
}
