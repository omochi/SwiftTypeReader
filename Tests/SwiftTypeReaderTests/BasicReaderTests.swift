import XCTest
import SwiftTypeReader

final class BasicReaderTests: ReaderTestCaseBase {
    func testReadmeExample() throws {
        try withExtendedLifetime(Context()) { (context) in
            let module = context.getOrCreateModule(name: "main")
            let reader = Reader(context: context, module: module)

            let source = try reader.read(
                source: """
struct S {
    var a: Int?
}
""",
                file: URL(fileURLWithPath: "S.swift")
            )
            _ = source

            let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
            XCTAssertEqual(s.name, "S")

            XCTAssertEqual(s.storedProperties.count, 1)
            let a = try XCTUnwrap(s.find(name: "a")?.asVar)
            XCTAssertIdentical(a, s.storedProperties[safe: 0])
            XCTAssertEqual(a.name, "a")

            let aType = try XCTUnwrap(a.interfaceType.asEnum)
            XCTAssertEqual(aType.name, "Optional")
            XCTAssertEqual(aType.genericArgs.count, 1)

            let aWrappedType = try XCTUnwrap(aType.genericArgs[safe: 0]?.asStruct)
            XCTAssertEqual(aWrappedType.name, "Int")
        }
    }

    func testSimpleStruct() throws {
        let module = try read("""
struct S {
    var a: Int?
}
"""
        )

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.moduleContext.name, "main")

        let a = try XCTUnwrap(s.find(name: "a")?.asVar)
        XCTAssertEqual(a.name, "a")

        XCTAssertEqual(s.storedProperties.count, 1)
        XCTAssertIdentical(s.storedProperties[safe: 0], a)

        let aType = try XCTUnwrap(a.interfaceType.asNominal)
        XCTAssertEqual(aType.description, "Optional<Int>")

        let aTypeDecl = aType.nominalTypeDecl

        XCTAssertEqual(aTypeDecl.moduleContext.name, "Swift")
        XCTAssertEqual(aTypeDecl.name, "Optional")
        XCTAssertEqual(aTypeDecl.declaredInterfaceType.description, "Optional<Wrapped>")

        XCTAssertEqual(aType.genericArgs.count, 1)

        let aWrappedType = try XCTUnwrap(aType.genericArgs[safe: 0]?.asStruct)
        XCTAssertEqual(aWrappedType.decl.moduleContext.name, "Swift")
        XCTAssertEqual(aWrappedType.decl.name, "Int")

        XCTAssertEqual(
            AnyTypeOptionalStorage(s.selfInterfaceType),
            AnyTypeOptionalStorage(s.declaredInterfaceType)
        )
    }

    func testTwoStruct() throws {
        let module = try read("""
struct S1 {
    var a: Int
    func b() -> S2 {}
}

public struct S2 {
    public var a: Int
}
"""
        )

        do {
            let s1 = try XCTUnwrap(module.find(name: "S1")?.asStruct)
            XCTAssertEqual(s1.name, "S1")

            let a = try XCTUnwrap(s1.find(name: "a")?.asVar)
            XCTAssertEqual(a.name, "a")
            XCTAssertEqual(a.interfaceType.asNominal?.name, "Int")

            let b = try XCTUnwrap(s1.find(name: "b")?.asFunc)
            XCTAssertEqual(b.name, "b")

            let s2 = try XCTUnwrap(b.resultInterfaceType.asStruct)
            XCTAssertEqual(s2.decl.name, "S2")
            XCTAssertEqual(s2.decl.storedProperties.count, 1)
        }

        do {
            let s2 = try XCTUnwrap(module.find(name: "S2")?.asStruct)
            XCTAssertEqual(s2.name, "S2")
            XCTAssertTrue(s2.modifiers.contains(.public))

            let a = try XCTUnwrap(s2.find(name: "a")?.asVar)
            XCTAssertEqual(a.name, "a")
            XCTAssertEqual(a.interfaceType.asNominal?.name, "Int")
            XCTAssertTrue(a.modifiers.contains(.public))
        }
    }

    func testUnknown() throws {
        let module = try read("""
struct S {
    var a: URL
}
"""
        )

        let s = try XCTUnwrap(module.findType(name: "S")?.asStruct)

        let a = try XCTUnwrap(s.find(name: "a")?.asVar)

        let aType = try XCTUnwrap(a.interfaceType.asError)
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

        let e = try XCTUnwrap(module.find(name: "E")?.asEnum)
        XCTAssertEqual(e.caseElements.count, 3)

        let a = try XCTUnwrap(e.find(name: "a")?.asEnumCaseElement)
        XCTAssertIdentical(e.caseElements[safe: 0], a)
        XCTAssertEqual(a.name, "a")
        XCTAssertEqual(a.associatedValues.count, 0)

        let b = try XCTUnwrap(e.find(name: "b")?.asEnumCaseElement)
        XCTAssertIdentical(e.caseElements[safe: 1], b)
        XCTAssertEqual(b.name, "b")

        XCTAssertEqual(b.associatedValues.count, 1)

        let bv = try XCTUnwrap(b.associatedValues[safe: 0])
        XCTAssertNil(bv.name)
        XCTAssertEqual(bv.interfaceType.asNominal?.name, "Int")

        let c = try XCTUnwrap(e.find(name: "c")?.asEnumCaseElement)
        XCTAssertIdentical(e.caseElements[safe: 2], c)
        XCTAssertEqual(c.name, "c")

        XCTAssertEqual(c.associatedValues.count, 2)

        let x = try XCTUnwrap(c.find(name: "x")?.asParam)
        XCTAssertIdentical(c.associatedValues[safe: 0], x)
        XCTAssertEqual(x.name, "x")
        XCTAssertEqual(x.interfaceType.asNominal?.name, "Int")

        let y = try XCTUnwrap(c.find(name: "y")?.asParam)
        XCTAssertIdentical(c.associatedValues[safe: 1], y)
        XCTAssertEqual(y.name, "y")
        XCTAssertEqual(y.interfaceType.asNominal?.name, "String")

        XCTAssertEqual(
            AnyTypeOptionalStorage(e.selfInterfaceType),
            AnyTypeOptionalStorage(e.declaredInterfaceType)
        )
    }

    func testProtocol() throws {
        let module = try read("""
protocol P: Encodable {
    associatedtype T: Decodable

    var a: String { mutating get async throws }
    static var b: Int { get nonmutating set }

    func c(x: Int) async throws -> Double
    static func d(_ x: Int, for y: Int)
}
""")
        let p = try XCTUnwrap(module.find(name: "P")?.asProtocol)

        let pg = p.genericParams
        XCTAssertEqual(pg.items.count, 1)
        let pSelf = try XCTUnwrap(pg.items[safe: 0])
        XCTAssertIdentical(pSelf.parentContext, p)
        XCTAssertEqual(pSelf.name, "Self")

        XCTAssertEqual(pSelf.inheritedTypes.count, 1)
        let pSelfP = try XCTUnwrap(pSelf.inheritedTypes[safe: 0]?.asProtocol?.decl)
        XCTAssertIdentical(pSelfP, p)

        XCTAssertEqual(
            AnyTypeOptionalStorage(p.selfInterfaceType),
            AnyTypeOptionalStorage(pSelf.declaredInterfaceType)
        )

        XCTAssertIdentical(
            p.findType(name: "Self")?.asGenericParam,
            pSelf
        )

        XCTAssertEqual(p.inheritedTypes.count, 1)
        let encodable = try XCTUnwrap(p.inheritedTypes[safe: 0]?.asProtocol)
        XCTAssertEqual(encodable.name, "Encodable")

        XCTAssertEqual(p.associatedTypes.count, 1)
        let t = try XCTUnwrap(p.find(name: "T")?.asAssociatedType)
        XCTAssertIdentical(p.associatedTypes[safe: 0], t)
        XCTAssertEqual(t.name, "T")

        XCTAssertEqual(p.properties.count, 2)

        let a = try XCTUnwrap(p.find(name: "a")?.asVar)
        XCTAssertIdentical(p.properties[safe: 0], a)
        XCTAssertFalse(a.modifiers.contains(.static))
        XCTAssertEqual(a.name, "a")
        XCTAssertEqual(a.interfaceType.description, "String")

        XCTAssertEqual(a.accessors.count, 1)
        let ag = try XCTUnwrap(a.accessors[safe: 0])
        XCTAssertEqual(ag.kind, .get)
        XCTAssertTrue(ag.modifiers.contains(.mutating))
        XCTAssertTrue(ag.modifiers.contains(.async))
        XCTAssertTrue(ag.modifiers.contains(.throws))

        let b = try XCTUnwrap(p.find(name: "b")?.asVar)
        XCTAssertIdentical(p.properties[safe: 1], b)
        XCTAssertTrue(b.modifiers.contains(.static))
        XCTAssertEqual(b.name, "b")
        XCTAssertEqual(b.interfaceType.description, "Int")

        XCTAssertEqual(b.accessors.count, 2)
        let bg = try XCTUnwrap(b.accessors[safe: 0])
        XCTAssertEqual(bg.kind, .get)
        let bs = try XCTUnwrap(b.accessors[safe: 1])
        XCTAssertEqual(bs.kind, .set)
        XCTAssertTrue(bs.modifiers.contains(.nonmutating))

        XCTAssertEqual(p.functions.count, 2)
        let c = try XCTUnwrap(p.find(name: "c")?.asFunc)
        XCTAssertIdentical(p.functions[safe: 0], c)
        XCTAssertFalse(c.modifiers.contains(.static))
        XCTAssertEqual(c.name, "c")
        XCTAssertEqual(c.parameters.count, 1)
        XCTAssertEqual(c.parameters[safe: 0]?.outerName, nil)
        XCTAssertEqual(c.parameters[safe: 0]?.name, "x")
        XCTAssertEqual(c.parameters[safe: 0]?.interfaceType.description, "Int")
        XCTAssertEqual(c.resultInterfaceType.description, "Double")
        XCTAssertTrue(c.modifiers.contains(.async))
        XCTAssertTrue(c.modifiers.contains(.throws))

        let d = try XCTUnwrap(p.find(name: "d")?.asFunc)
        XCTAssertIdentical(p.functions[safe: 1], d)
        XCTAssertTrue(d.modifiers.contains(.static))
        XCTAssertEqual(d.parameters.count, 2)
        XCTAssertEqual(d.parameters[safe: 0]?.outerName, nil)
        XCTAssertEqual(d.parameters[safe: 0]?.name, "x")
        XCTAssertEqual(d.parameters[safe: 0]?.interfaceType.description, "Int")
        XCTAssertEqual(d.parameters[safe: 1]?.outerName, "for")
        XCTAssertEqual(d.parameters[safe: 1]?.name, "y")
        XCTAssertEqual(d.parameters[safe: 1]?.interfaceType.description, "Int")
        XCTAssertNil(d.resultTypeRepr)
        XCTAssertEqual(d.resultInterfaceType.description, "Void")
        XCTAssertFalse(d.modifiers.contains(.async))
        XCTAssertFalse(d.modifiers.contains(.throws))
    }

    func testSimpleClass() throws {
        let module = try read("""
class C {
    var a: Int?
    func f(s: S) throws {}
}
"""
        )

        let s = try XCTUnwrap(module.find(name: "C")?.asClass)
        XCTAssertEqual(s.name, "C")

        XCTAssertEqual(s.moduleContext.name, "main")

        let a = try XCTUnwrap(s.find(name: "a")?.asVar)
        XCTAssertEqual(a.name, "a")

        XCTAssertEqual(s.storedProperties.count, 1)
        XCTAssertIdentical(s.storedProperties[safe: 0], a)

        let aType = try XCTUnwrap(a.interfaceType.asNominal)
        XCTAssertEqual(aType.description, "Optional<Int>")

        let f = try XCTUnwrap(s.find(name: "f")?.asFunc)
        XCTAssertEqual(f.name, "f")
        XCTAssertEqual(f.parameters.count, 1)
        XCTAssertEqual(f.parameters[safe: 0]?.interfaceName, "s")
        XCTAssertEqual(f.parameters[safe: 0]?.interfaceType.description, "S")
        XCTAssertTrue(f.modifiers.contains(.throws))
        XCTAssertEqual(f.resultInterfaceType.description, "Void")

        XCTAssertEqual(
            AnyTypeOptionalStorage(s.selfInterfaceType),
            AnyTypeOptionalStorage(s.declaredInterfaceType)
        )
    }

    func testStructProperty() throws {
        let module = try read("""
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

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        XCTAssertEqual(s.properties.count, 3)
        XCTAssertEqual(s.storedProperties.count, 1)
        XCTAssertEqual(s.computedProperties.count, 2)

        let a = try XCTUnwrap(s.find(name: "a")?.asVar)
        XCTAssertIdentical(s.computedProperties[safe: 0], a)
        XCTAssertEqual(a.propertyKind, .computed)
        XCTAssertEqual(a.name, "a")
        XCTAssertEqual(a.accessors.count, 1)
        XCTAssertEqual(a.accessors[safe: 0]?.kind, .get)

        let b = try XCTUnwrap(s.find(name: "b")?.asVar)
        XCTAssertIdentical(s.storedProperties[safe: 0], b)
        XCTAssertEqual(b.propertyKind, .stored)
        XCTAssertEqual(b.name, "b")
        XCTAssertEqual(b.interfaceType.asNominal?.name, "Int")
        XCTAssertEqual(b.accessors.count, 2)
        XCTAssertEqual(b.accessors[safe: 0]?.kind, .willSet)
        XCTAssertEqual(b.accessors[safe: 1]?.kind, .didSet)

        let c = try XCTUnwrap(s.find(name: "c")?.asVar)
        XCTAssertIdentical(s.computedProperties[safe: 1], c)
        XCTAssertEqual(c.propertyKind, .computed)
        XCTAssertEqual(c.name, "c")
        XCTAssertEqual(c.interfaceType.description, "Int")
        XCTAssertEqual(c.accessors.count, 1)
        XCTAssertEqual(c.accessors[safe: 0]?.kind, .get)
    }

    func testFunctionType() throws {
        let module = try read("""
struct S {
    var a: (Int) -> Void
}
""")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        let a = try XCTUnwrap(s.find(name: "a")?.asVar)
        let f = try XCTUnwrap(a.interfaceType.asFunction)
        XCTAssertEqual(f.description, "(Int) -> Void")
        XCTAssertEqual(f.params.count, 1)
        XCTAssertEqual(f.params[safe: 0]?.description, "Int")
        XCTAssertEqual(f.result.description, "Void")
    }

    func testMethodInterfaceType() throws {
        let module = try read("""
struct S {
    func f()
}

protocol P {
    func f()
}
""")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        let sf = try XCTUnwrap(s.find(name: "f")?.asFunc)
        XCTAssertEqual(sf.interfaceType.description, "(S) -> () -> Void")
        XCTAssertEqual(sf.selfAppliedInterfaceType.description, "() -> Void")

        let p = try XCTUnwrap(module.find(name: "P")?.asProtocol)
        let pf = try XCTUnwrap(p.find(name: "f")?.asFunc)
        XCTAssertEqual(pf.interfaceType.description, "(Self) -> () -> Void")
        XCTAssertEqual(pf.selfAppliedInterfaceType.description, "() -> Void")
    }

    func testInheritanceClause() throws {
        let module = try read("""
struct S: Encodable {}

enum E: Decodable {
    case a
}
""")

        do{
            let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
            XCTAssertEqual(s.inheritedTypes.count, 1)
            let e = try XCTUnwrap(s.inheritedTypes[safe: 0]?.asProtocol)
            XCTAssertEqual(e.decl.moduleContext.name, "Swift")
            XCTAssertEqual(e.name, "Encodable")
        }

        do {
            let e = try XCTUnwrap(module.find(name: "E")?.asEnum)
            XCTAssertEqual(e.inheritedTypes.count, 1)
            let d = try XCTUnwrap(e.inheritedTypes[safe: 0]?.asProtocol)
            XCTAssertEqual(d.decl.moduleContext.name, "Swift")
            XCTAssertEqual(d.name, "Decodable")
        }
    }

    func testGenericParameter() throws {
        let module = try read("""
struct S<T> {
    var a: T
}
"""
        )

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.genericParams.items.count, 1)
        let t = try XCTUnwrap(s.genericParams.items[safe: 0])
        XCTAssertIdentical(s.find(name: "T"), t)
        XCTAssertEqual(t.name, "T")

        XCTAssertEqual(s.storedProperties.count, 1)
        let a = try XCTUnwrap(s.storedProperties[safe: 0])
        XCTAssertIdentical(s.find(name: "a"), a)
        XCTAssertEqual(a.name, "a")

        let aT = try XCTUnwrap(a.interfaceType.asGenericParam)
        XCTAssertIdentical(aT.decl, t)
    }

    func testIdentTypeRepr() throws {
        let module = try read("""
struct S {
    var a: A.B
    var b: A.B.C
    var c: main.K
}

struct K {}
"""
        )

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.storedProperties.count, 3)

        let a = try XCTUnwrap(s.find(name: "a")?.asVar)
        XCTAssertEqual(a.name, "a")
        let aTypeRepr = try XCTUnwrap(a.typeRepr.asIdent)
        XCTAssertEqual(aTypeRepr.elements, [.init(name: "A"), .init(name: "B")])
        let aType = try XCTUnwrap(a.interfaceType.asError)
        XCTAssertEqual(aType.description, "A.B")

        let b = try XCTUnwrap(s.find(name: "b")?.asVar)
        XCTAssertEqual(b.name, "b")
        let bTypeRepr = try XCTUnwrap(b.typeRepr.asIdent)
        XCTAssertEqual(bTypeRepr.elements, [.init(name: "A"), .init(name: "B"), .init(name: "C")])
        let bType = try XCTUnwrap(b.interfaceType.asError)
        XCTAssertEqual(bType.description, "A.B.C")

        let c = try XCTUnwrap(s.find(name: "c")?.asVar)
        XCTAssertEqual(c.name, "c")
        let cTypeRepr = try XCTUnwrap(c.typeRepr.asIdent)
        XCTAssertEqual(cTypeRepr.elements, [.init(name: "main"), .init(name: "K")])
        let cType = try XCTUnwrap(c.interfaceType.asStruct)
        XCTAssertIdentical(module.find(name: "K"), cType.decl)
    }

    func testNestedTypeInStruct() throws {
        let module = try read("""
struct A {
    struct B {}
}
"""
        )

        XCTAssertEqual(module.types.count, 1)
        let a = try XCTUnwrap(module.find(name: "A")?.asStruct)
        XCTAssertEqual(a.name, "A")
        let aType = try XCTUnwrap(a.declaredInterfaceType.asStruct)
        XCTAssertNil(aType.parent)

        XCTAssertEqual(a.types.count, 1)
        let b = try XCTUnwrap(a.find(name: "B")?.asStruct)
        XCTAssertEqual(b.name, "B")
        XCTAssertIdentical(b.parentContext, a)
        let bType = try XCTUnwrap(b.declaredInterfaceType.asStruct)
        XCTAssertEqual(bType.description, "A.B")
        XCTAssertEqual(bType.parent?.description, "A")
    }

    func testNestedTypeInEnum() throws {
        let module = try read("""
enum A {
    struct B {}
}
"""
        )

        let a = try XCTUnwrap(module.find(name: "A")?.asEnum)
        XCTAssertEqual(a.name, "A")

        let b = try XCTUnwrap(a.find(name: "B")?.asStruct)
        XCTAssertEqual(b.name, "B")
        XCTAssertIdentical(b.parentContext, a)

        let bType = try XCTUnwrap(b.declaredInterfaceType.asStruct)
        XCTAssertEqual(bType.description, "A.B")
        XCTAssertEqual(bType.parent?.description, "A")
    }

    func testResolveNestedTypes() throws {
        let module = try read("""
struct A {
    struct B {}

    var x: B
}

struct B {}

struct C {
    var y: B
}
""")
        let a = try XCTUnwrap(module.find(name: "A")?.asStruct)
        let b = try XCTUnwrap(module.find(name: "B")?.asStruct)
        let aB = try XCTUnwrap(a.find(name: "B")?.asStruct)
        XCTAssertNotIdentical(b, aB)

        let xb = try XCTUnwrap(a.find(name: "x")?.asVar?.interfaceType.asStruct?.decl)
        XCTAssertIdentical(xb, aB)

        let c = try XCTUnwrap(module.find(name: "C")?.asStruct)

        let yb = try XCTUnwrap(c.find(name: "y")?.asVar?.interfaceType.asStruct?.decl)
        XCTAssertIdentical(yb, b)
    }

    func testImportDecl() throws {
        let source = try Reader(
            context: context
        ).read(
            source: """
import Foo
@preconcurrency import Bar
import struct Baz.S
""",
            file: URL(fileURLWithPath: "main.swift")
        )

        let i0 = try XCTUnwrap(source.imports[safe: 0])
        XCTAssertEqual(i0.moduleName, "Foo")
        let i1 = try XCTUnwrap(source.imports[safe: 1])
        XCTAssertEqual(i1.moduleName, "Bar")
        let i2 = try XCTUnwrap(source.imports[safe: 2])
        XCTAssertEqual(i2.moduleName, "Baz")
        XCTAssertEqual(i2.declName, "S")
    }

    func testImportResolution() throws {
        let moduleA = context.getOrCreateModule(name: "A")
        _ = try Reader(
            context: context,
            module: moduleA
        ).read(
            source: """
public struct X {}
""",
            file: URL(fileURLWithPath: "X.swift")
        )

        let moduleB = context.getOrCreateModule(name: "B")
        _ = try Reader(
            context: context,
            module: moduleB
        ).read(
            source: """
public enum X {}
""",
            file: URL(fileURLWithPath: "X.swift")
        )

        let moduleC = context.getOrCreateModule(name: "C")
        let reader = Reader(
            context: context,
            module: moduleC
        )

        _ = try reader.read(
            source: """
import A

struct S {
    var x: X
}
""",
            file: URL(fileURLWithPath: "S.swift")
        )

        _ = try reader.read(
            source: """
import B

struct K {
    var x: X
}
""",
            file: URL(fileURLWithPath: "K.swift")
        )

        let aX = try XCTUnwrap(moduleA.find(name: "X")?.asStruct)
        let bX = try XCTUnwrap(moduleB.find(name: "X")?.asEnum)
        let s = try XCTUnwrap(moduleC.find(name: "S")?.asStruct)
        let sX = try XCTUnwrap(s.find(name: "x")?.asVar)
        let sXType = try XCTUnwrap(sX.interfaceType.asNominal)
        XCTAssertIdentical(sXType.nominalTypeDecl, aX)
        let k = try XCTUnwrap(moduleC.find(name: "K")?.asStruct)
        let kX = try XCTUnwrap(k.find(name: "x")?.asVar)
        let kXType = try XCTUnwrap(kX.interfaceType.asNominal)
        XCTAssertIdentical(kXType.nominalTypeDecl, bX)
    }

    func testScopedImport() throws {
        let a = context.getOrCreateModule(name: "A")
        _ = try Reader(context: context, module: a).read(
            source: """
struct S {}
struct K {}
""",
            file: URL(fileURLWithPath: "a.swift")
        )

        let aS = try XCTUnwrap(a.find(name: "S")?.asStruct)
        let aK = try XCTUnwrap(a.find(name: "K")?.asStruct)

        let main = context.getOrCreateModule(name: "main")
        let mainSource = try Reader(context: context, module: main).read(
            source: """
import struct A.S
""",
            file: URL(fileURLWithPath: "main.swift")
        )

        let mS1 = try XCTUnwrap(
            IdentTypeRepr([.init(name: "S")])
                .resolve(from: mainSource).asStruct
        )
        XCTAssertIdentical(mS1.decl, aS)

        let mK1 = try XCTUnwrap(
            IdentTypeRepr([.init(name: "K")])
                .resolve(from: mainSource).asError
        )
        _ = mK1

        let mS2 = try XCTUnwrap(
            IdentTypeRepr([.init(name: "A"), .init(name: "S")])
                .resolve(from: mainSource).asStruct
        )
        XCTAssertIdentical(mS2.decl, aS)

        let mK2 = try XCTUnwrap(
            IdentTypeRepr([.init(name: "A"), .init(name: "K")])
                .resolve(from: mainSource).asStruct
        )
        XCTAssertIdentical(mK2.decl, aK)
    }

    func testModules() throws {
        let myLib = context.getOrCreateModule(name: "MyLib")
        _ = try Reader(
            context: context,
            module: myLib
        ).read(
            source: """
public enum E {
    case a
}
""",
            file: URL(fileURLWithPath: "MyLib.swift")
        )

        let main = context.getOrCreateModule(name: "main")
        let mainSource = try Reader(
            context: context,
            module: main
        ).read(
            source: """
import MyLib

protocol P {
    func f() -> E
}
""",
            file: URL(fileURLWithPath: "main.swift")
        )

        let p = try XCTUnwrap(main.find(name: "P")?.asProtocol)
        XCTAssertEqual(p.name, "P")
        let f = try XCTUnwrap(p.functions[safe: 0])
        XCTAssertEqual(f.name, "f")
        let e = try XCTUnwrap(f.resultInterfaceType.asEnum?.decl)
        XCTAssertIdentical(e, myLib.find(name: "E"))
        let ea = try XCTUnwrap(e.caseElements[safe: 0])
        XCTAssertEqual(ea.name, "a")

        XCTAssertEqual(mainSource.imports[safe: 0]?.moduleName, "MyLib")
    }

    func testTopLevelTypeAlias() throws {
        let module = try read("""
public typealias A = Int
"""
        )

        let ad = try XCTUnwrap(module.find(name: "A")?.asTypeAlias)
        XCTAssertEqual(ad.name, "A")
        XCTAssertEqual(ad.genericParams.items.count, 0)
        XCTAssertEqual(ad.contextGenericSignature.description, "")
        XCTAssertEqual(ad.underlyingType.description, "Int")
        XCTAssertTrue(ad.modifiers.contains(.public))

        let a = try XCTUnwrap(ad.declaredInterfaceType.asTypeAlias)
        XCTAssertEqual(a.description, "A")
        XCTAssertEqual(a.name, "A")
        XCTAssertNil(a.parent)
        XCTAssertEqual(a.genericArgs.count, 0)
        XCTAssertEqual(a.underlyingType.description, "Int")
    }

    func testNestedTypeAlias() throws {
        let module = try read("""
struct S {
    typealias A = Int
}
""")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        let ad = try XCTUnwrap(s.find(name: "A")?.asTypeAlias)
        XCTAssertEqual(ad.name, "A")
        XCTAssertEqual(ad.genericParams.items.count, 0)
        XCTAssertEqual(ad.contextGenericSignature.description, "")
        XCTAssertEqual(ad.underlyingType.description, "Int")

        let a = try XCTUnwrap(ad.declaredInterfaceType.asTypeAlias)
        XCTAssertEqual(a.description, "S.A")
        XCTAssertEqual(a.name, "A")
        XCTAssertEqual(a.parent?.description, "S")
        XCTAssertEqual(a.genericArgs.count, 0)
        XCTAssertEqual(a.underlyingType.description, "Int")
    }

    func testSpecializedTypeAlias() throws {
        let module = try read("""
struct K<T> {}

struct S {
    typealias A = K<Int>
}
""")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        let ad = try XCTUnwrap(s.find(name: "A")?.asTypeAlias)
        XCTAssertEqual(ad.name, "A")
        XCTAssertEqual(ad.genericParams.items.count, 0)
        XCTAssertEqual(ad.contextGenericSignature.description, "")
        XCTAssertEqual(ad.underlyingType.description, "K<Int>")

        let a = try XCTUnwrap(ad.declaredInterfaceType.asTypeAlias)
        XCTAssertEqual(a.description, "S.A")
        XCTAssertEqual(a.name, "A")
        XCTAssertEqual(a.parent?.description, "S")
        XCTAssertEqual(a.genericArgs.count, 0)
        XCTAssertEqual(a.underlyingType.description, "K<Int>")
    }

    func testGenericTypeAlias() throws {
        let module = try read("""
struct K<T> {}

struct S {
    typealias A<V> = K<V>
}

struct D {
    var b: S.A<Int>
}
""")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        let ad = try XCTUnwrap(s.find(name: "A")?.asTypeAlias)
        XCTAssertEqual(ad.name, "A")
        XCTAssertEqual(ad.genericParams.items.count, 1)
        XCTAssertEqual(ad.contextGenericSignature.description, "<V>")
        XCTAssertEqual(ad.underlyingType.description, "K<V>")

        let a = try XCTUnwrap(ad.declaredInterfaceType.asTypeAlias)
        XCTAssertEqual(a.description, "S.A<V>")
        XCTAssertEqual(a.name, "A")
        XCTAssertEqual(a.parent?.description, "S")
        XCTAssertEqual(a.genericArgs.count, 1)
        XCTAssertEqual(a.genericArgs[safe: 0]?.description, "V")
        XCTAssertEqual(a.underlyingType.description, "K<V>")

        let d = try XCTUnwrap(module.find(name: "D")?.asStruct)
        let b = try XCTUnwrap(d.find(name: "b")?.asVar)
        let bt = try XCTUnwrap(b.interfaceType.asTypeAlias)
        XCTAssertEqual(bt.underlyingType.description, "K<Int>")
    }

    func testOuterParamTypeAlias() throws {
        let module = try read("""
struct K<T> {}

struct S<V> {
    typealias A = K<V>
}

struct D {
    var b: S<Int>.A
}
""")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        let ad = try XCTUnwrap(s.find(name: "A")?.asTypeAlias)
        XCTAssertEqual(ad.name, "A")
        XCTAssertEqual(ad.genericParams.items.count, 0)
        XCTAssertEqual(ad.contextGenericSignature.description, "<V>")
        XCTAssertEqual(ad.underlyingType.description, "K<V>")

        let a = try XCTUnwrap(ad.declaredInterfaceType.asTypeAlias)
        XCTAssertEqual(a.description, "S<V>.A")
        XCTAssertEqual(a.name, "A")
        XCTAssertEqual(a.parent?.description, "S<V>")
        XCTAssertEqual(a.genericArgs.count, 0)
        XCTAssertEqual(a.underlyingType.description, "K<V>")

        let d = try XCTUnwrap(module.find(name: "D")?.asStruct)
        let b = try XCTUnwrap(d.find(name: "b")?.asVar)
        let bt = try XCTUnwrap(b.interfaceType.asTypeAlias)
        XCTAssertEqual(bt.underlyingType.description, "K<Int>")
    }

    func testOuterParamGenericTypeAlias() throws {
        let module = try read("""
struct K<T, U> {}

struct S<V> {
    typealias A<W> = K<V, W>
}

struct D {
    var b: S<Int>.A<Bool>
}
""")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        let ad = try XCTUnwrap(s.find(name: "A")?.asTypeAlias)
        XCTAssertEqual(ad.name, "A")
        XCTAssertEqual(ad.genericParams.items.count, 1)
        XCTAssertEqual(ad.contextGenericSignature.description, "<V, W>")
        XCTAssertEqual(ad.underlyingType.description, "K<V, W>")

        let a = try XCTUnwrap(ad.declaredInterfaceType.asTypeAlias)
        XCTAssertEqual(a.description, "S<V>.A<W>")
        XCTAssertEqual(a.name, "A")
        XCTAssertEqual(a.parent?.description, "S<V>")
        XCTAssertEqual(a.genericArgs.count, 1)
        XCTAssertEqual(a.genericArgs[safe: 0]?.description, "W")
        XCTAssertEqual(a.underlyingType.description, "K<V, W>")

        let d = try XCTUnwrap(module.find(name: "D")?.asStruct)
        let b = try XCTUnwrap(d.find(name: "b")?.asVar)
        let bt = try XCTUnwrap(b.interfaceType.asTypeAlias)
        XCTAssertEqual(bt.underlyingType.description, "K<Int, Bool>")
    }

    func testTopLevelFunc() throws {
        let module = try read("""
public func f() {
}
""")

        let f = try XCTUnwrap(module.find(name: "f")?.asFunc)
        XCTAssertTrue(f.modifiers.contains(.public))
        XCTAssertEqual(f.parameters, [])
    }

    func testInitializer() throws {
        let module = try read("""
struct S {
    init() {}
}
class C {
    init(a: Int) throws {}
}
""")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        XCTAssertEqual(s.initializers.count, 1)
        XCTAssertEqual(s.initializers[safe: 0]?.parameters.count, 0)

        let c = try XCTUnwrap(module.find(name: "C")?.asClass)
        XCTAssertEqual(c.initializers.count, 1)
        XCTAssertEqual(c.initializers[safe: 0]?.parameters.count, 1)
        XCTAssertEqual(c.initializers[safe: 0]?.parameters[safe: 0]?.typeRepr.description, "Int")
        XCTAssertEqual(c.initializers[safe: 0]?.modifiers.contains(.throws), true)
        XCTAssertEqual(c.initializers[safe: 0]?.interfaceType.description, "(Int) throws -> C")
    }

    func testParamDecl() throws {
        let module = try read("""
func f1(a: Int) {}
func f2(b c: Int) {}
func f3(_ d: Int) {}
func f4(Int) {}
func f5(_: Int) {}
func f6(e _: Int) {}
""")

        let f1Param0 = try XCTUnwrap(module.find(name: "f1")?.asFunc?.parameters[safe: 0])
        XCTAssertEqual(f1Param0.outerName, nil)
        XCTAssertEqual(f1Param0.name, "a")
        XCTAssertEqual(f1Param0.syntaxOuterName, nil)
        XCTAssertEqual(f1Param0.syntaxName, "a")
        XCTAssertEqual(f1Param0.interfaceName, "a")

        let f2Param0 = try XCTUnwrap(module.find(name: "f2")?.asFunc?.parameters[safe: 0])
        XCTAssertEqual(f2Param0.outerName, "b")
        XCTAssertEqual(f2Param0.name, "c")
        XCTAssertEqual(f2Param0.syntaxOuterName, "b")
        XCTAssertEqual(f2Param0.syntaxName, "c")
        XCTAssertEqual(f2Param0.interfaceName, "b")

        let f3Param0 = try XCTUnwrap(module.find(name: "f3")?.asFunc?.parameters[safe: 0])
        XCTAssertEqual(f3Param0.outerName, nil)
        XCTAssertEqual(f3Param0.name, "d")
        XCTAssertEqual(f3Param0.syntaxOuterName, "_")
        XCTAssertEqual(f3Param0.syntaxName, "d")
        XCTAssertEqual(f3Param0.interfaceName, nil)

        let f4Param0 = try XCTUnwrap(module.find(name: "f4")?.asFunc?.parameters[safe: 0])
        XCTAssertEqual(f4Param0.outerName, nil)
        XCTAssertEqual(f4Param0.name, nil)
        XCTAssertEqual(f4Param0.syntaxOuterName, nil)
        XCTAssertEqual(f4Param0.syntaxName, nil)
        XCTAssertEqual(f4Param0.interfaceName, nil)

        let f5Param0 = try XCTUnwrap(module.find(name: "f5")?.asFunc?.parameters[safe: 0])
        XCTAssertEqual(f5Param0.outerName, nil)
        XCTAssertEqual(f5Param0.name, nil)
        XCTAssertEqual(f5Param0.syntaxOuterName, nil)
        XCTAssertEqual(f5Param0.syntaxName, "_")
        XCTAssertEqual(f5Param0.interfaceName, nil)

        let f6Param0 = try XCTUnwrap(module.find(name: "f6")?.asFunc?.parameters[safe: 0])
        XCTAssertEqual(f6Param0.outerName, "e")
        XCTAssertEqual(f6Param0.name, nil)
        XCTAssertEqual(f6Param0.syntaxOuterName, "e")
        XCTAssertEqual(f6Param0.syntaxName, "_")
        XCTAssertEqual(f6Param0.interfaceName, "e")
    }
}
