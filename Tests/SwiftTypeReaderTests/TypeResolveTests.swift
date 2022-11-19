import XCTest
import SwiftTypeReader

final class TypeResolveTests: ReaderTestCaseBase {
    func testResolveFullPath() throws {
        let module = try read("""
struct G<T> {}

struct A {
    struct B {
        struct C {}
    }

    struct G<T> {}
}
""")

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(.init(name: "Swift")),
                from: module
            ),
            "Swift"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(.init(name: "Swift"), .init(name: "Int")),
                from: module
            ),
            "Swift.Int"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(.init(name: "main")),
                from: module
            ),
            "main"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "main"),
                    .init(name: "G", genericArgs: [
                        IdentTypeRepr(.init(name: "Int"))
                    ])
                ),
                from: module
            ),
            "main.G<Swift.Int>"
        )

        do {
            let g = try XCTUnwrap(module.find(name: "G") as? StructDecl)
            let t = try XCTUnwrap(g.find(name: "T") as? GenericParamDecl)
            XCTAssertEqual(t.name, "T")
            XCTAssertIdentical(t.parentContext, g)
        }

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "main"),
                    .init(name: "A"),
                    .init(name: "B")
                ),
                from: module
            ),
            "main.A.B"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "main"),
                    .init(name: "A"),
                    .init(name: "B"),
                    .init(name: "C")
                ),
                from: module
            ),
            "main.A.B.C"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "main"),
                    .init(name: "A"),
                    .init(name: "G", genericArgs: [
                        IdentTypeRepr(.init(name: "Int"))
                    ])
                ),
                from: module
            ),
            "main.A.G<Swift.Int>"
        )


        do {
            let a = try XCTUnwrap(module.find(name: "A") as? StructDecl)
            let g = try XCTUnwrap(a.find(name: "G") as? StructDecl)
            XCTAssertEqual(g.name, "G")
            XCTAssertIdentical(g.parentContext, a)
            let t = try XCTUnwrap(g.find(name: "T") as? GenericParamDecl)
            XCTAssertEqual(t.name, "T")
            XCTAssertIdentical(t.parentContext, g)
        }
    }

    func testFromContext() throws {
        let module = try read("""
struct A {
    struct A {
        struct A {
        }
    }
}
"""
        )

        // from top level

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A")
                ),
                from: module
            ),
            "main.A"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: module
            ),
            "main.A.A"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A"),
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: module
            ),
            "main.A.A.A"
        )

        let a1 = try XCTUnwrap(module.find(name: "A") as? any NominalTypeDecl)

        // from A

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A")
                ),
                from: a1
            ),
            "main.A.A"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: a1
            ),
            "main.A.A.A"
        )

        XCTAssertTrue(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A"),
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: a1
            ) is ErrorType
        )

        let a2 = try XCTUnwrap(a1.find(name: "A") as? any NominalTypeDecl)

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A")
                ),
                from: a2
            ),
            "main.A.A.A"
        )

        XCTAssertTrue(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: a2
            ) is ErrorType
        )

        let a3 = try XCTUnwrap(a2.find(name: "A") as? any NominalTypeDecl)

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A")
                ),
                from: a3
            ),
            "main.A.A.A"
        )

        XCTAssertTrue(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: a3
            ) is ErrorType
        )

        // Absolute path is context agnostic

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "main"),
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: module
            ),
            "main.A.A"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "main"),
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: a1
            ),
            "main.A.A"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "main"),
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: a2
            ),
            "main.A.A"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "main"),
                    .init(name: "A"),
                    .init(name: "A")
                ),
                from: a3
            ),
            "main.A.A"
        )
    }

    func testCrossModuleResolve() throws {
        let moduleX = context.getOrCreateModule(name: "X")
        _ = try Reader(
            context: context,
            module: moduleX
        ).read(
            source: """
struct Int {
}
""",
            file: URL(fileURLWithPath: "x.swift")
        )

        let moduleY = context.getOrCreateModule(name: "Y")
        let readerY = Reader(
            context: context,
            module: moduleY
        )

        _ = try readerY.read(
            source: """
struct A {
    struct Int {

    }
}
""",
            file: URL(fileURLWithPath: "y.swift")
        )

        let y2Swift = try readerY.read(
            source: """
import X
""",
            file: URL(fileURLWithPath: "y2.swift")
        )


        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "Int")
                ),
                from: moduleY
            ),
            "Swift.Int"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "Int")
                ),
                from: moduleX
            ),
            "X.Int"
        )

        let yA = try XCTUnwrap(moduleY.find(name: "A") as? StructDecl)

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "Int")
                ),
                from: yA
            ),
            "Y.A.Int"
        )

        assertFullPath(
            resolve(
                repr: IdentTypeRepr(
                    .init(name: "Int")
                ),
                from: y2Swift
            ),
            "X.Int"
        )
    }

    func resolve(
        repr: IdentTypeRepr, from: any DeclContext,
        file: StaticString = #file, line: UInt = #line
    ) -> any SType2 {
        repr.resolve(from: from)
    }

    func assertFullPath(
        _ type: any SType2, _ expected: String,
        file: StaticString = #file, line: UInt = #line
    ) {
        XCTAssertEqual(
            type.toTypeRepr(containsModule: true).description,
            expected
        )
    }
}
