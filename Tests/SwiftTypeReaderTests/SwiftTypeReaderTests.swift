import XCTest
@testable import SwiftTypeReader

func XCTReadTypes(_ source: String, file: StaticString = #file, line: UInt = #line) throws -> Reader.Result {
    return try Reader(modules: nil).read(source: source)
}

final class SwiftTypeReaderTests: XCTestCase {
    func testSimple() throws {
        let result = try XCTReadTypes("""
struct S {
    var a: Int?
}
"""
        )

        let s = try XCTUnwrap(result.module.types[safe: 0]?.struct)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.location, Location([.module(name: "main")]))

        XCTAssertEqual(s.storedProperties.count, 1)
        let a = try XCTUnwrap(s.storedProperties[safe: 0])
        XCTAssertEqual(a.name, "a")

        let aType = try XCTUnwrap(a.type().struct)
        XCTAssertEqual(aType.module?.name, "Swift")
        XCTAssertEqual(aType.name, "Optional")
        XCTAssertEqual(try aType.genericArguments().count, 1)

        let aWrappedType = try XCTUnwrap(aType.genericArguments()[safe: 0]?.struct)
        XCTAssertEqual(aWrappedType.module?.name, "Swift")
        XCTAssertEqual(aWrappedType.name, "Int")
    }

    func testReader() throws {
        let result = try XCTReadTypes("""
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
            let s1 = try XCTUnwrap(result.module.types[safe: 0]?.struct)
            XCTAssertEqual(s1.name, "S1")

            let a = try XCTUnwrap(s1.storedProperties[safe: 0])
            XCTAssertEqual(a.name, "a")
            XCTAssertEqual(try a.type().name, "Int")

            let b = try XCTUnwrap(s1.storedProperties[safe: 1])
            XCTAssertEqual(b.name, "b")

            let s2 = try XCTUnwrap(try b.type().struct)
            XCTAssertEqual(s2.name, "S2")
            XCTAssertEqual(s2.storedProperties.count, 1)
        }

        do {
            let s2 = try XCTUnwrap(result.module.types[safe: 1]?.struct)
            XCTAssertEqual(s2.name, "S2")

            let a = try XCTUnwrap(s2.storedProperties[safe: 0])
            XCTAssertEqual(a.name, "a")
            XCTAssertEqual(try a.type().name, "Int")
        }

    }

    func testUnresolved() throws {
        let result = try XCTReadTypes("""
struct S {
    var a: URL
}
"""
        )

        let s = try XCTUnwrap(result.module.types[safe: 0]?.struct)

        let a = try XCTUnwrap(s.storedProperties[safe: 0]?.type().unresolved)
        XCTAssertEqual(a.lastElement.name, "URL")
    }

    func testEnum() throws {
        let result = try XCTReadTypes("""
enum E {
    case a
    case b(Int)
    case c(x: Int, y: Int)
}
"""
        )

        let e = try XCTUnwrap(result.module.types[safe: 0]?.enum)

        do {
            let c = try XCTUnwrap(e.caseElements[safe: 0])
            XCTAssertEqual(c.name, "a")
        }

        do {
            let c = try XCTUnwrap(e.caseElements[safe: 1])
            XCTAssertEqual(c.name, "b")

            let x = try XCTUnwrap(c.associatedValues[safe: 0])
            XCTAssertNil(x.name)
            XCTAssertEqual(try x.type().name, "Int")
        }

        do {
            let c = try XCTUnwrap(e.caseElements[safe: 2])
            XCTAssertEqual(c.name, "c")

            let x = try XCTUnwrap(c.associatedValues[safe: 0])
            XCTAssertEqual(x.name, "x")
            XCTAssertEqual(try x.type().name, "Int")

            let y = try XCTUnwrap(c.associatedValues[safe: 1])
            XCTAssertEqual(y.name, "y")
            XCTAssertEqual(try y.type().name, "Int")
        }
    }

    func testProtocol() throws {
        let result = try XCTReadTypes("""
protocol P: Encodable {
    associatedtype T: Decodable
    var a: String { mutating get async throws }
    func b(x: Int) async throws -> Double
    static var c: Int { get nonmutating set }
    static func d(_ x: Int, for y: Int)
}
""")
        let p = try XCTUnwrap(result.module.types[safe: 0]?.protocol)

        XCTAssertEqual(try p.inheritedTypes().first?.name, "Encodable")
        XCTAssertEqual(p.associatedTypes, ["T"])

        do {
            let a = try XCTUnwrap(p.propertyRequirements[safe: 0])
            XCTAssertEqual(a.name, "a")
            XCTAssertEqual(a.unresolvedType.name, "String")
            XCTAssertEqual(a.accessors, [.get(mutating: true, async: true, throws: true)])
            XCTAssertEqual(a.isStatic, false)
        }

        do {
            let b = try XCTUnwrap(p.functionRequirements[safe: 0])
            XCTAssertEqual(b.name, "b")
            XCTAssertEqual(b.parameters.first?.label, nil)
            XCTAssertEqual(b.parameters.first?.name, "x")
            XCTAssertEqual(b.parameters.first?.unresolvedType.name, "Int")
            XCTAssertEqual(b.unresolvedOutputType?.name, "Double")
            XCTAssertEqual(b.isAsync, true)
            XCTAssertEqual(b.isThrows, true)
            XCTAssertEqual(b.isStatic, false)
        }

        do {
            let c = try XCTUnwrap(p.propertyRequirements[safe: 1])
            XCTAssertEqual(c.name, "c")
            XCTAssertEqual(c.unresolvedType.name, "Int")
            XCTAssertEqual(c.accessors, [.get(), .set(nonmutating: true)])
            XCTAssertEqual(c.isStatic, true)
        }

        do {
            let d = try XCTUnwrap(p.functionRequirements[safe: 1])
            XCTAssertEqual(d.name, "d")
            XCTAssertEqual(d.parameters.first?.label, "_")
            XCTAssertEqual(d.parameters.first?.name, "x")
            XCTAssertEqual(d.parameters.first?.unresolvedType.name, "Int")
            XCTAssertEqual(d.parameters[safe: 1]?.label, "for")
            XCTAssertEqual(d.parameters[safe: 1]?.name, "y")
            XCTAssertEqual(d.parameters[safe: 1]?.unresolvedType.name, "Int")
            XCTAssertEqual(d.unresolvedOutputType?.name, nil)
            XCTAssertEqual(d.isAsync, false)
            XCTAssertEqual(d.isThrows, false)
            XCTAssertEqual(d.isStatic, true)
        }
    }

    func testObservedStoredProperty() throws {
        let result = try XCTReadTypes("""
struct S {
    var a: Int { 0 }
    var b: Int = 0 {
        willSet {}
        didSet {}
    }
    var c: Int {
        get { 0 }
    }
"""
        )

        let s = try XCTUnwrap(result.module.types[safe: 0]?.struct)

        XCTAssertEqual(s.storedProperties.count, 1)

        let b = try XCTUnwrap(s.storedProperties[safe: 0])
        XCTAssertEqual(b.name, "b")
        XCTAssertEqual(try b.type().name, "Int")
    }

    func testInheritanceClause() throws {
        let result = try XCTReadTypes("""
enum E: Codable {
    case a
}
""")
        let e = try XCTUnwrap(result.module.types[safe: 0]?.enum)

        XCTAssertEqual(try e.inheritedTypes().count, 1)

        let c = try XCTUnwrap(e.inheritedTypes()[safe: 0])
        XCTAssertNotNil(c.protocol)
        XCTAssertEqual(c.protocol?.module?.name, "Swift")
        XCTAssertEqual(c.name, "Codable")
    }

    func testGenericParameter() throws {
        let result = try XCTReadTypes("""
struct S<T> {
    var a: T
}
"""
        )

        let s = try XCTUnwrap(result.module.types[safe: 0]?.struct)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.genericParameters.count, 1)
        let t = try XCTUnwrap(s.genericParameters[safe: 0])
        XCTAssertEqual(t.name, "T")

        XCTAssertEqual(s.storedProperties.count, 1)
        let a = try XCTUnwrap(s.storedProperties[safe: 0])
        XCTAssertEqual(a.name, "a")

        let at = try XCTUnwrap(a.type().genericParameter)
        XCTAssertEqual(
            at.location,
            Location([
                .module(name: "main"),
                .type(name: "S")
            ])
        )
    }

    func testNestedTypeProperty() throws {
        let result = try XCTReadTypes("""
struct S {
    var x: A.B
    var y: A.B.C
}
"""
        )

        let s = try XCTUnwrap(result.module.types[safe: 0]?.struct)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.storedProperties.count, 2)

        let x = try XCTUnwrap(s.storedProperties[safe: 0])
        XCTAssertEqual(x.name, "x")
        XCTAssertEqual(try x.type().description, "A.B")

        let y = try XCTUnwrap(s.storedProperties[safe: 1])
        XCTAssertEqual(y.name, "y")
        XCTAssertEqual(try y.type().description, "A.B.C")
    }

    func testModules() throws {
        let modules = Modules()
        _ = try Reader(modules: modules, moduleName: "MyLib").read(source: """
enum E {
    case a
}
"""
        )

        let result = try Reader(modules: modules, moduleName: "main").read(source: """
import MyLib

protocol P {
    func f() -> E
}
"""
        )

        let p = try XCTUnwrap(result.module.types[safe: 0]?.protocol)
        XCTAssertEqual(p.name, "P")
        let f = try XCTUnwrap(p.functionRequirements[safe: 0])
        XCTAssertEqual(f.name, "f")
        let e = try XCTUnwrap(try f.outputType()?.enum)
        let c = try XCTUnwrap(e.caseElements[safe: 0])
        XCTAssertEqual(c.name, "a")
    }
}
