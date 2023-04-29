import XCTest
import SwiftTypeReader

class ReaderTestCaseBase: XCTestCase {
    var context: Context!

    override func setUp() {
        context = Context()
    }

    override func tearDown() {
        context = nil
    }

    func read(_ source: String, file: StaticString = #file, line: UInt = #line) -> Module {
        let reader = Reader(context: context!)
        _ = reader.read(source: source, file: URL(fileURLWithPath: "main.swift"))
        return reader.module
    }
}
