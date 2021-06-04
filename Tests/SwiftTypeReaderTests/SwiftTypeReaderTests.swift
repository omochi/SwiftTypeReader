import XCTest
@testable import SwiftTypeReader

final class SwiftTypeReaderTests: XCTestCase {
    func testSimple() throws {
        let reader = Reader()

        let source = """
struct S {
    var a: Int?
}
"""
        let result = try reader.read(source: source)

        let s = try XCTUnwrap(result.types[safe: 0]?.struct)
        XCTAssertEqual(s.name, "S")

        XCTAssertEqual(s.storedProperties.count, 1)
        let a = try XCTUnwrap(s.storedProperties[safe: 0])
        XCTAssertEqual(a.name, "a")

        let aType = try XCTUnwrap(a.type?.struct)
        XCTAssertEqual(aType.name, "Optional")
        XCTAssertEqual(aType.genericsArguments.count, 1)

        let aWrappedType = try XCTUnwrap(aType.genericsArguments[safe: 0]?.struct)
        XCTAssertEqual(aWrappedType.name, "Int")
    }

    func testReader() throws {
        let reader = Reader()

        let source = """
struct S1 {
    var a: Int
    var b: S2
}

struct S2 {
    var a: Int
}
"""

        let result = try reader.read(source: source)

        do {
            let s1 = try XCTUnwrap(result.types[safe: 0]?.struct)
            XCTAssertEqual(s1.name, "S1")

            let a = try XCTUnwrap(s1.storedProperties[safe: 0])
            XCTAssertEqual(a.name, "a")
            XCTAssertEqual(a.type?.name, "Int")

            let b = try XCTUnwrap(s1.storedProperties[safe: 1])
            XCTAssertEqual(b.name, "b")

            let s2 = try XCTUnwrap(b.type?.struct)
            XCTAssertEqual(s2.name, "S2")
            XCTAssertEqual(s2.storedProperties.count, 1)
        }

        do {
            let s2 = try XCTUnwrap(result.types[safe: 1]?.struct)
            XCTAssertEqual(s2.name, "S2")

            let a = try XCTUnwrap(s2.storedProperties[safe: 0])
            XCTAssertEqual(a.name, "a")
            XCTAssertEqual(a.type?.name, "Int")
        }

    }

    func testUnresolved() throws {
        let reader = Reader()

        let source = """
struct S {
    var a: URL
}
"""
        let result = try reader.read(source: source)

        let s = try XCTUnwrap(result.types[safe: 0]?.struct)

        let a = try XCTUnwrap(s.storedProperties[safe: 0]?.type?.unresolved)
        XCTAssertEqual(a.name, "URL")
    }
}
