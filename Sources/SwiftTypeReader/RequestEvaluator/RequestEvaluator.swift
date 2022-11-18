import Collections

public final class RequestEvaluator {
    public init() {
        resultCache = .init()
        activeRequests = .init()
    }

    private var resultCache: Dictionary<AnyKey, Any>
    private var activeRequests: OrderedSet<AnyKey>

    public func callAsFunction<Q: Request>(_ request: Q) throws -> Q.Result {
        return try evaluate(request)
    }

    public func evaluate<Q: Request>(_ request: Q) throws -> Q.Result {
        let key = AnyKey(request)

        if let anyResult = resultCache[key],
           let typedResult = anyResult as? Q.Result
        {
            return typedResult
        }

        if activeRequests.contains(key) {
            throw CycleRequestError(request: request)
        }

        activeRequests.append(key)
        let result = Result<Q.Result, _> {
            let result = try request.evaluate(on: self)
            self.resultCache[key] = result
            return result
        }
        activeRequests.remove(key)
        return try result.get()
    }
}
