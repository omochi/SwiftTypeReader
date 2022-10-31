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
            try context.resolve(
                location: Location([.module(name: "Swift")])
            )?.module?.name,
            "Swift"
        )

        XCTAssertEqual(
            try context.resolve(
                location: Location([.module(name: "Swift"), .type(name: "Int")])
            )?.type?.asSpecifier().elements,
            [.init(name: "Swift"), .init(name: "Int")]
        )

        XCTAssertEqual(
            try context.resolve(
                location: Location([.module(name: "main")])
            )?.module?.name,
            "main"
        )

        XCTAssertEqual(
            try context.resolve(
                location: Location([.module(name: "main"), .type(name: "G")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "G")]
        )

        do {
            let t = try XCTUnwrap(
                try context.resolve(
                    location: Location([.module(name: "main"), .type(name: "G"), .genericParameter(index: 0)])
                )?.type
            )

            XCTAssertEqual(
                try t.location(),
                Location([.module(name: "main"), .type(name: "G")])
            )
            XCTAssertEqual(
                t.asSpecifier().elements,
                [.init(name: "T")]
            )
        }

        XCTAssertEqual(
            try context.resolve(
                location: Location([.module(name: "main"), .type(name: "A"), .type(name: "B")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "B")]
        )

        XCTAssertEqual(
            try context.resolve(
                location: Location([.module(name: "main"), .type(name: "A"), .type(name: "B"), .type(name: "C")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "B"), .init(name: "C")]
        )

        XCTAssertEqual(
            try context.resolve(
                location: Location([.module(name: "main"), .type(name: "A"), .type(name: "G")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "G")]
        )

        do {
            let t = try XCTUnwrap(
                try context.resolve(
                    location: Location([.module(name: "main"), .type(name: "A"), .type(name: "G"), .genericParameter(index: 0)])
                )?.type
            )

            XCTAssertEqual(
                try t.location(),
                Location([.module(name: "main"), .type(name: "A"), .type(name: "G")])
            )
            XCTAssertEqual(
                t.asSpecifier().elements,
                [.init(name: "T")]
            )
        }
    }
}
