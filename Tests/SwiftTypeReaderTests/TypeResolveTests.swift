import XCTest
import SwiftTypeReader

final class TypeResolveTests: ReaderTestCaseBase {
    func testTypeResolve() throws {
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

        XCTAssertEqual(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main")]),
                elements: [.init(name: "A")]
            ).resolve().asSpecifier().elements,
            [.init(name: "main"), .init(name: "A")]
        )

        XCTAssertEqual(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main")]),
                elements: [.init(name: "A"), .init(name: "A")]
            ).resolve().asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "A")]
        )

        XCTAssertEqual(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main")]),
                elements: [.init(name: "A"), .init(name: "A"), .init(name: "A")]
            ).resolve().asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "A"), .init(name: "A")]
        )

        // from A

        XCTAssertEqual(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main"), .type(name: "A")]),
                elements: [.init(name: "A")]
            ).resolve().asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "A")]
        )

        XCTAssertEqual(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main"), .type(name: "A")]),
                elements: [.init(name: "A"), .init(name: "A")]
            ).resolve().asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "A"), .init(name: "A")]
        )

        XCTAssertNotNil(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main"), .type(name: "A")]),
                elements: [.init(name: "A"), .init(name: "A"), .init(name: "A")]
            ).resolve().unresolved
        )

        // from A.A

        XCTAssertEqual(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main"), .type(name: "A"), .type(name: "A")]),
                elements: [.init(name: "A")]
            ).resolve().asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "A"), .init(name: "A")]
        )

        XCTAssertNotNil(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main"), .type(name: "A"), .type(name: "A")]),
                elements: [.init(name: "A"), .init(name: "A")]
            ).resolve().unresolved
        )

        // Absolute spec is location agnostic

        XCTAssertEqual(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main")]),
                elements: [.init(name: "main"), .init(name: "A"), .init(name: "A")]
            ).resolve().asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "A")]
        )

        XCTAssertEqual(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main"), .type(name: "A")]),
                elements: [.init(name: "main"), .init(name: "A"), .init(name: "A")]
            ).resolve().asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "A")]
        )

        XCTAssertEqual(
            try TypeSpecifier(
                module: module, file: nil,
                location: Location([.module(name: "main"), .type(name: "A"), .type(name: "A")]),
                elements: [.init(name: "main"), .init(name: "A"), .init(name: "A")]
            ).resolve().asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "A")]
        )
    }

    func testCrossModuleResolve() throws {
        let moduleX = try Reader(
            context: context,
            module: context.getOrCreateModule(name: "X")
        ).read(source: """
struct Int {
}
"""
        )

        let moduleY = try Reader(
            context: context,
            module: context.getOrCreateModule(name: "Y")
        ).read(source: """
struct A {
    struct Int {

    }
}
"""
        )

        XCTAssertEqual(
            try TypeSpecifier(
                module: moduleY, file: nil,
                location: Location([.module(name: "Y")]),
                elements: [.init(name: "Int")]
            ).resolve().asSpecifier().elements,
            [.init(name: "Swift"), .init(name: "Int")]
        )

        XCTAssertEqual(
            try TypeSpecifier(
                module: moduleX, file: nil,
                location: Location([.module(name: "X")]),
                elements: [.init(name: "Int")]
            ).resolve().asSpecifier().elements,
            [.init(name: "X"), .init(name: "Int")]
        )

        XCTAssertEqual(
            try TypeSpecifier(
                module: moduleY, file: nil,
                location: Location([.module(name: "Y"), .type(name: "A")]),
                elements: [.init(name: "Int")]
            ).resolve().asSpecifier().elements,
            [.init(name: "Y"), .init(name: "A"), .init(name: "Int")]
        )
    }
}
