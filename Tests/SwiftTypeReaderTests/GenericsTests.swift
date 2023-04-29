import XCTest
import SwiftTypeReader

final class GenericsTests: ReaderTestCaseBase {
    func testSubst() throws {
        let module = read("""
struct S<T> {
    var a: T
}

struct K {
    var v: S<Int>
}
"""
        )

        let k = try XCTUnwrap(module.find(name: "K")?.asStruct)
        let v = try XCTUnwrap(k.find(name: "v")?.asVar)

        let map = v.interfaceType.contextSubstitutionMap()
        XCTAssertEqual(map.signature.params.count, 1)
        XCTAssertEqual(map.signature.params[safe: 0]?.description, "T")
        XCTAssertEqual(map.replacementTypes[safe: 0]?.description, "Int")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        let a = try XCTUnwrap(s.find(name: "a")?.asVar)

        let at = a.interfaceType
        XCTAssertEqual(at.description, "T")
        XCTAssertEqual(at.subst(map: map).description, "Int")
    }

    func testNestedSubst() throws {
        let module = read("""
struct O<T> {
    struct S<U> {
        var a: T
        var b: U
    }
}

struct K {
    var v: O<Int>.S<String>
}
"""
        )

        let k = try XCTUnwrap(module.find(name: "K")?.asStruct)
        let v = try XCTUnwrap(k.find(name: "v")?.asVar)

        let map = v.interfaceType.contextSubstitutionMap()
        XCTAssertEqual(map.signature.params.count, 2)
        XCTAssertEqual(map.signature.params[safe: 0]?.description, "T")
        XCTAssertEqual(map.replacementTypes[safe: 0]?.description, "Int")
        XCTAssertEqual(map.signature.params[safe: 1]?.description, "U")
        XCTAssertEqual(map.replacementTypes[safe: 1]?.description, "String")


        let o = try XCTUnwrap(module.find(name: "O")?.asStruct)
        let s = try XCTUnwrap(o.find(name: "S")?.asStruct)
        let a = try XCTUnwrap(s.find(name: "a")?.asVar)
        let b = try XCTUnwrap(s.find(name: "b")?.asVar)

        XCTAssertEqual(a.interfaceType.subst(map: map).description, "Int")
        XCTAssertEqual(b.interfaceType.subst(map: map).description, "String")
    }

    func testSubstParam() throws {
        let module = read("""
struct S<T> {
    var a: T
}

struct K<U> {
    var v: S<U>
}
"""
        )

        let k = try XCTUnwrap(module.find(name: "K")?.asStruct)
        let v = try XCTUnwrap(k.find(name: "v")?.asVar)

        let map = v.interfaceType.contextSubstitutionMap()
        XCTAssertEqual(map.signature.params.count, 1)
        XCTAssertEqual(map.signature.params[safe: 0]?.description, "T")
        XCTAssertEqual(map.replacementTypes[safe: 0]?.description, "U")

        let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
        let a = try XCTUnwrap(s.find(name: "a")?.asVar)

        XCTAssertEqual(a.interfaceType.subst(map: map).description, "U")
    }

}
