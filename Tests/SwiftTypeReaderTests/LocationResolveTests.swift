import XCTest
import SwiftTypeReader

final class LocationResolveTests: XCTestCase {
    func testLocationResolve() throws {
        let modules = Modules()

        _ = try Reader(modules: modules, moduleName: "main").read(source: """
struct G<T> {}

struct A {
    struct B {
        struct C {}
    }

    struct G<T> {}
}
""")

        XCTAssertEqual(
            try modules.resolve(
                location: Location([.module(name: "Swift")])
            )?.module?.name,
            "Swift"
        )

        XCTAssertEqual(
            try modules.resolve(
                location: Location([.module(name: "Swift"), .type(name: "Int")])
            )?.type?.asSpecifier().elements,
            [.init(name: "Swift"), .init(name: "Int")]
        )

        XCTAssertEqual(
            try modules.resolve(
                location: Location([.module(name: "main")])
            )?.module?.name,
            "main"
        )

        XCTAssertEqual(
            try modules.resolve(
                location: Location([.module(name: "main"), .type(name: "G")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "G")]
        )

        do {
            let t = try XCTUnwrap(
                try modules.resolve(
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
            try modules.resolve(
                location: Location([.module(name: "main"), .type(name: "A"), .type(name: "B")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "B")]
        )

        XCTAssertEqual(
            try modules.resolve(
                location: Location([.module(name: "main"), .type(name: "A"), .type(name: "B"), .type(name: "C")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "B"), .init(name: "C")]
        )

        XCTAssertEqual(
            try modules.resolve(
                location: Location([.module(name: "main"), .type(name: "A"), .type(name: "G")])
            )?.type?.asSpecifier().elements,
            [.init(name: "main"), .init(name: "A"), .init(name: "G")]
        )

        do {
            let t = try XCTUnwrap(
                try modules.resolve(
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
