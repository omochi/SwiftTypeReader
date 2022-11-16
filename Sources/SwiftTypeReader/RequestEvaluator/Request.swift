public protocol Request: Hashable {
    associatedtype Result

    func evaluate(on evaluator: RequestEvaluator) throws -> Result
}
