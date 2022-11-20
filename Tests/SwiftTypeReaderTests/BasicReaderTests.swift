import XCTest
import SwiftTypeReader

final class BasicReaderTests: ReaderTestCaseBase {
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

        let aWrappedType = try XCTUnwrap(aType.genericArgs[safe: 0] as? StructType)
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

            let s2 = try XCTUnwrap(b.interfaceType as? StructType)
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

        let aType = try XCTUnwrap(a.interfaceType as? ErrorType)
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

        let a = try XCTUnwrap(e.find(name: "a") as? EnumCaseElementDecl)
        XCTAssertIdentical(e.caseElements[safe: 0], a)
        XCTAssertEqual(a.name, "a")
        XCTAssertEqual(a.associatedValues.count, 0)

        let b = try XCTUnwrap(e.find(name: "b") as? EnumCaseElementDecl)
        XCTAssertIdentical(e.caseElements[safe: 1], b)
        XCTAssertEqual(b.name, "b")

        XCTAssertEqual(b.associatedValues.count, 1)

        let bv = try XCTUnwrap(b.associatedValues[safe: 0])
        XCTAssertNil(bv.name)
        XCTAssertEqual((bv.interfaceType as? any NominalType)?.name, "Int")

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
        let p = try XCTUnwrap(module.find(name: "P") as? ProtocolDecl)

        let pg = p.genericParams
        XCTAssertEqual(pg.items.count, 1)
        let pSelf = try XCTUnwrap(pg.items[safe: 0])
        XCTAssertIdentical(pSelf.parentContext, p)
        XCTAssertEqual(pSelf.name, "Self")

        XCTAssertEqual(pSelf.inheritedTypes.count, 1)
        let pSelfP = try XCTUnwrap((pSelf.inheritedTypes[safe: 0] as? ProtocolType)?.decl)
        XCTAssertIdentical(pSelfP, p)

        XCTAssertEqual(
            AnyTypeOptionalStorage(p.selfInterfaceType),
            AnyTypeOptionalStorage(pSelf.declaredInterfaceType)
        )

        XCTAssertIdentical(
            p.findType(name: "Self") as? GenericParamDecl,
            pSelf
        )

        XCTAssertEqual(p.inheritedTypes.count, 1)
        let encodable = try XCTUnwrap(p.inheritedTypes[safe: 0] as? ProtocolType)
        XCTAssertEqual(encodable.name, "Encodable")

        XCTAssertEqual(p.associatedTypes.count, 1)
        let t = try XCTUnwrap(p.find(name: "T") as? AssociatedTypeDecl)
        XCTAssertIdentical(p.associatedTypes[safe: 0], t)
        XCTAssertEqual(t.name, "T")

        XCTAssertEqual(p.propertyRequirements.count, 2)

        let a = try XCTUnwrap(p.find(name: "a") as? VarDecl)
        XCTAssertIdentical(p.propertyRequirements[safe: 0], a)
        XCTAssertFalse(a.modifiers.contains(.static))
        XCTAssertEqual(a.name, "a")
        XCTAssertEqual(a.interfaceType.description, "String")

        XCTAssertEqual(a.accessors.count, 1)
        let ag = try XCTUnwrap(a.accessors[safe: 0])
        XCTAssertEqual(ag.kind, .get)
        XCTAssertTrue(ag.modifiers.contains(.mutating))
        XCTAssertTrue(ag.modifiers.contains(.async))
        XCTAssertTrue(ag.modifiers.contains(.throws))

        let b = try XCTUnwrap(p.find(name: "b") as? VarDecl)
        XCTAssertIdentical(p.propertyRequirements[safe: 1], b)
        XCTAssertTrue(b.modifiers.contains(.static))
        XCTAssertEqual(b.name, "b")
        XCTAssertEqual(b.interfaceType.description, "Int")

        XCTAssertEqual(b.accessors.count, 2)
        let bg = try XCTUnwrap(b.accessors[safe: 0])
        XCTAssertEqual(bg.kind, .get)
        let bs = try XCTUnwrap(b.accessors[safe: 1])
        XCTAssertEqual(bs.kind, .set)
        XCTAssertTrue(bs.modifiers.contains(.nonmutating))

        XCTAssertEqual(p.functionRequirements.count, 2)
        let c = try XCTUnwrap(p.find(name: "c") as? FuncDecl)
        XCTAssertIdentical(p.functionRequirements[safe: 0], c)
        XCTAssertFalse(c.modifiers.contains(.static))
        XCTAssertEqual(c.name, "c")
        XCTAssertEqual(c.parameters.count, 1)
        XCTAssertEqual(c.parameters[safe: 0]?.interfaceName, "x")
        XCTAssertEqual(c.parameters[safe: 0]?.name, "x")
        XCTAssertEqual(c.parameters[safe: 0]?.interfaceType.description, "Int")
        XCTAssertEqual(c.resultInterfaceType.description, "Double")
        XCTAssertTrue(c.modifiers.contains(.async))
        XCTAssertTrue(c.modifiers.contains(.throws))

        let d = try XCTUnwrap(p.find(name: "d") as? FuncDecl)
        XCTAssertIdentical(p.functionRequirements[safe: 1], d)
        XCTAssertTrue(d.modifiers.contains(.static))
        XCTAssertEqual(d.parameters.count, 2)
        XCTAssertEqual(d.parameters[safe: 0]?.interfaceName, "_")
        XCTAssertEqual(d.parameters[safe: 0]?.name, "x")
        XCTAssertEqual(d.parameters[safe: 0]?.interfaceType.description, "Int")
        XCTAssertEqual(d.parameters[safe: 1]?.interfaceName, "for")
        XCTAssertEqual(d.parameters[safe: 1]?.name, "y")
        XCTAssertEqual(d.parameters[safe: 1]?.interfaceType.description, "Int")
        XCTAssertNil(d.resultTypeRepr)
        XCTAssertEqual(d.resultInterfaceType.description, "Void")
        XCTAssertFalse(d.modifiers.contains(.async))
        XCTAssertFalse(d.modifiers.contains(.throws))
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

        let s = try XCTUnwrap(module.find(name: "S") as? StructDecl)
        XCTAssertEqual(s.properties.count, 3)
        XCTAssertEqual(s.storedProperties.count, 1)
        XCTAssertEqual(s.computedProperties.count, 2)

        let a = try XCTUnwrap(s.find(name: "a") as? VarDecl)
        XCTAssertIdentical(s.computedProperties[safe: 0], a)
        XCTAssertEqual(a.propertyKind, .computed)
        XCTAssertEqual(a.name, "a")
        XCTAssertEqual(a.accessors.count, 1)
        XCTAssertEqual(a.accessors[safe: 0]?.kind, .get)

        let b = try XCTUnwrap(s.find(name: "b") as? VarDecl)
        XCTAssertIdentical(s.storedProperties[safe: 0], b)
        XCTAssertEqual(b.propertyKind, .stored)
        XCTAssertEqual(b.name, "b")
        XCTAssertEqual((b.interfaceType as? any NominalType)?.name, "Int")
        XCTAssertEqual(b.accessors.count, 2)
        XCTAssertEqual(b.accessors[safe: 0]?.kind, .willSet)
        XCTAssertEqual(b.accessors[safe: 1]?.kind, .didSet)

        let c = try XCTUnwrap(s.find(name: "c") as? VarDecl)
        XCTAssertIdentical(s.computedProperties[safe: 1], c)
        XCTAssertEqual(c.propertyKind, .computed)
        XCTAssertEqual(c.name, "c")
        XCTAssertEqual(c.interfaceType.description, "Int")
        XCTAssertEqual(c.accessors.count, 1)
        XCTAssertEqual(c.accessors[safe: 0]?.kind, .get)
    }

    func testInheritanceClause() throws {
        let module = try read("""
struct S: Encodable {}

enum E: Decodable {
    case a
}
""")

        do{
            let s = try XCTUnwrap(module.find(name: "S") as? StructDecl)
            XCTAssertEqual(s.inheritedTypes.count, 1)
            let e = try XCTUnwrap(s.inheritedTypes[safe: 0] as? ProtocolType)
            XCTAssertEqual(e.decl.moduleContext.name, "Swift")
            XCTAssertEqual(e.name, "Encodable")
        }

        do {
            let e = try XCTUnwrap(module.find(name: "E") as? EnumDecl)
            XCTAssertEqual(e.inheritedTypes.count, 1)
            let d = try XCTUnwrap(e.inheritedTypes[safe: 0] as? ProtocolType)
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

        let s = try XCTUnwrap(module.find(name: "S") as? StructDecl)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.genericParams.items.count, 1)
        let t = try XCTUnwrap(s.genericParams.items[safe: 0])
        XCTAssertIdentical(s.find(name: "T"), t)
        XCTAssertEqual(t.name, "T")

        XCTAssertEqual(s.storedProperties.count, 1)
        let a = try XCTUnwrap(s.storedProperties[safe: 0])
        XCTAssertIdentical(s.find(name: "a"), a)
        XCTAssertEqual(a.name, "a")

        let aT = try XCTUnwrap(a.interfaceType as? GenericParamType)
        XCTAssertIdentical(aT.decl, t)
    }

    func testChainedTypeRepr() throws {
        let module = try read("""
struct S {
    var a: A.B
    var b: A.B.C
    var c: main.K
}

struct K {}
"""
        )

        let s = try XCTUnwrap(module.find(name: "S") as? StructDecl)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.storedProperties.count, 3)

        let a = try XCTUnwrap(s.find(name: "a") as? VarDecl)
        XCTAssertEqual(a.name, "a")
        let aTypeRepr = try XCTUnwrap(a.typeRepr as? IdentTypeRepr)
        XCTAssertEqual(aTypeRepr.elements, [.init(name: "A"), .init(name: "B")])
        let aType = try XCTUnwrap(a.interfaceType as? ErrorType)
        XCTAssertEqual(aType.description, "A.B")

        let b = try XCTUnwrap(s.find(name: "b") as? VarDecl)
        XCTAssertEqual(b.name, "b")
        let bTypeRepr = try XCTUnwrap(b.typeRepr as? IdentTypeRepr)
        XCTAssertEqual(bTypeRepr.elements, [.init(name: "A"), .init(name: "B"), .init(name: "C")])
        let bType = try XCTUnwrap(b.interfaceType as? ErrorType)
        XCTAssertEqual(bType.description, "A.B.C")

        let c = try XCTUnwrap(s.find(name: "c") as? VarDecl)
        XCTAssertEqual(c.name, "c")
        let cTypeRepr = try XCTUnwrap(c.typeRepr as? IdentTypeRepr)
        XCTAssertEqual(cTypeRepr.elements, [.init(name: "main"), .init(name: "K")])
        let cType = try XCTUnwrap(c.interfaceType as? StructType)
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
        let a = try XCTUnwrap(module.find(name: "A") as? StructDecl)
        XCTAssertEqual(a.name, "A")
        let aType = try XCTUnwrap(a.declaredInterfaceType as? StructType)
        XCTAssertNil(aType.parent)

        XCTAssertEqual(a.types.count, 1)
        let b = try XCTUnwrap(a.find(name: "B") as? StructDecl)
        XCTAssertEqual(b.name, "B")
        XCTAssertIdentical(b.parentContext, a)
        let bType = try XCTUnwrap(b.declaredInterfaceType as? StructType)
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

        let a = try XCTUnwrap(module.find(name: "A") as? EnumDecl)
        XCTAssertEqual(a.name, "A")

        let b = try XCTUnwrap(a.find(name: "B") as? StructDecl)
        XCTAssertEqual(b.name, "B")
        XCTAssertIdentical(b.parentContext, a)

        let bType = try XCTUnwrap(b.declaredInterfaceType as? StructType)
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
        let a = try XCTUnwrap(module.find(name: "A") as? StructDecl)
        let b = try XCTUnwrap(module.find(name: "B") as? StructDecl)
        let aB = try XCTUnwrap(a.find(name: "B") as? StructDecl)
        XCTAssertNotIdentical(b, aB)

        let xb = try XCTUnwrap(((a.find(name: "x") as? VarDecl)?.interfaceType as? StructType)?.decl)
        XCTAssertIdentical(xb, aB)

        let c = try XCTUnwrap(module.find(name: "C") as? StructDecl)

        let yb = try XCTUnwrap(((c.find(name: "y") as? VarDecl)?.interfaceType as? StructType)?.decl)
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

        let aX = try XCTUnwrap(moduleA.find(name: "X") as? StructDecl)
        let bX = try XCTUnwrap(moduleB.find(name: "X") as? EnumDecl)
        let s = try XCTUnwrap(moduleC.find(name: "S") as? StructDecl)
        let sX = try XCTUnwrap(s.find(name: "x") as? VarDecl)
        let sXType = try XCTUnwrap(sX.interfaceType as? any NominalType)
        XCTAssertIdentical(sXType.nominalTypeDecl, aX)
        let k = try XCTUnwrap(moduleC.find(name: "K") as? StructDecl)
        let kX = try XCTUnwrap(k.find(name: "x") as? VarDecl)
        let kXType = try XCTUnwrap(kX.interfaceType as? any NominalType)
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

        let aS = try XCTUnwrap(a.find(name: "S") as? StructDecl)
        let aK = try XCTUnwrap(a.find(name: "K") as? StructDecl)

        let main = context.getOrCreateModule(name: "main")
        let mainSource = try Reader(context: context, module: main).read(
            source: """
import struct A.S
""",
            file: URL(fileURLWithPath: "main.swift")
        )

        let mS1 = try XCTUnwrap(
            IdentTypeRepr([.init(name: "S")])
                .resolve(from: mainSource) as? StructType
        )
        XCTAssertIdentical(mS1.decl, aS)

        let mK1 = try XCTUnwrap(
            IdentTypeRepr([.init(name: "K")])
                .resolve(from: mainSource) as? ErrorType
        )
        _ = mK1

        let mS2 = try XCTUnwrap(
            IdentTypeRepr([.init(name: "A"), .init(name: "S")])
                .resolve(from: mainSource) as? StructType
        )
        XCTAssertIdentical(mS2.decl, aS)

        let mK2 = try XCTUnwrap(
            IdentTypeRepr([.init(name: "A"), .init(name: "K")])
                .resolve(from: mainSource) as? StructType
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

        let p = try XCTUnwrap(main.find(name: "P") as? ProtocolDecl)
        XCTAssertEqual(p.name, "P")
        let f = try XCTUnwrap(p.functionRequirements[safe: 0])
        XCTAssertEqual(f.name, "f")
        let e = try XCTUnwrap((f.resultInterfaceType as? EnumType)?.decl)
        XCTAssertIdentical(e, myLib.find(name: "E"))
        let ea = try XCTUnwrap(e.caseElements[safe: 0])
        XCTAssertEqual(ea.name, "a")

        XCTAssertEqual(mainSource.imports[safe: 0]?.moduleName, "MyLib")
    }
}
