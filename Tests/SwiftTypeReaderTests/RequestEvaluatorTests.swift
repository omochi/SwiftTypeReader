import XCTest
import SwiftTypeReader

final class RequestEvaluatorTests: XCTestCase {
    func tarai(_ x: Int, _ y: Int, _ z: Int) -> Int {
        if x <= y { return y }
        return tarai(
            tarai(x - 1, y, z),
            tarai(y - 1, z, x),
            tarai(z - 1, x, y)
        )
    }

    struct Tarai: Request {
        var x: Int
        var y: Int
        var z: Int
        func evaluate(on evaluator: RequestEvaluator) throws -> Int {
            if x <= y { return y }
            return try evaluator(
                Tarai(
                    x: evaluator(Tarai(x: x - 1, y: y, z: z)),
                    y: evaluator(Tarai(x: y - 1, y: z, z: x)),
                    z: evaluator(Tarai(x: z - 1, y: x, z: y))
                )
            )
        }
    }

    func testTarai() throws {
        // tarai(15, 10, 0)
        
        let evaluator = RequestEvaluator()
        XCTAssertEqual(
            try evaluator(Tarai(x: 15, y: 10, z: 0)),
            15
        )
    }

    struct CycleA: Request {
        func evaluate(on evaluator: RequestEvaluator) throws -> Int {
            return try evaluator(CycleB())
        }
    }

    struct CycleB: Request {
        func evaluate(on evaluator: RequestEvaluator) throws -> Int {
            return try evaluator(CycleA())
        }
    }

    func testCycle() throws {
        let evaluator = RequestEvaluator()
        XCTAssertThrowsError(try evaluator(CycleA())) { (error) in
            XCTAssertTrue(error is CycleRequestError)
        }
    }
}
