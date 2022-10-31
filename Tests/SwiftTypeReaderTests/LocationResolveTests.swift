import XCTest
import SwiftTypeReader

final class LocationResolveTests: ReaderTestCaseBase {
    func testLocationResolve() throws {
        _ = try read("""
struct G<T> {}

struct A {
    struct B {
        struct C {}
    }

    struct G<T> {}
}
""")

        XCTAssertEqual(
            context.resolve(
                location: Location(module: "Swift")
            )?.module?.name,
            "Swift"
        )

        XCTAssertEqual(
            context.resolve(
                location: Location(module: "Swift", elements: [.type(name: "Int")])
            )?.type?.asSpecifier().elements,
            [.init(name: "Swift"), .init(name: "Int")]
        )

        XCTAssertEqual(
            context.resolve(
                location: Location(module: "main")
            )?.module?.name,
            "main"
        )

        XCTAssertEqual(
            context.resolve(
                location: Location(module: "main", elements: [.type(name: "G")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "G")]
        )

        do {
            let t = try XCTUnwrap(
                context.resolve(
                    location: Location(module: "main", elements: [.type(name: "G"), .genericParameter(index: 0)])
                )?.type
            )

            XCTAssertEqual(
                t.regular?.location,
                Location(module: "main", elements: [.type(name: "G")])
            )
            XCTAssertEqual(
                t.asSpecifier().elements,
                [.init(name: "T")]
            )
        }

        XCTAssertEqual(
            context.resolve(
                location: Location(module: "main", elements: [.type(name: "A"), .type(name: "B")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "B")]
        )

        XCTAssertEqual(
            context.resolve(
                location: Location(module: "main", elements: [.type(name: "A"), .type(name: "B"), .type(name: "C")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "B"), .init(name: "C")]
        )

        XCTAssertEqual(
            context.resolve(
                location: Location(module: "main", elements: [.type(name: "A"), .type(name: "G")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "G")]
        )

        do {
            let t = try XCTUnwrap(
                context.resolve(
                    location: Location(
                        module: "main",
                        elements: [.type(name: "A"), .type(name: "G"), .genericParameter(index: 0)]
                    )
                )?.type
            )

            XCTAssertEqual(
                t.regular?.location,
                Location(module: "main", elements: [.type(name: "A"), .type(name: "G")])
            )
            XCTAssertEqual(
                t.asSpecifier().elements,
                [.init(name: "T")]
            )
        }
    }
}
