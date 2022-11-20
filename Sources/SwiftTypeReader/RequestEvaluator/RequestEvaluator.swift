import Collections

public final class RequestEvaluator {
    public init() {
        resultCache = .init()
        activeRequests = .init()
    }

    private var resultCache: Dictionary<AnyKey, Result<Any, Swift.Error>>
    private var activeRequests: OrderedSet<AnyKey>

    public func callAsFunction<Q: Request>(_ request: Q) throws -> Q.Result {
        return try evaluate(request)
    }

    public func evaluate<Q: Request>(_ request: Q) throws -> Q.Result {
        let key = AnyKey(request)

        if let cacheEntry = resultCache[key],
           case let anyResult = try cacheEntry.get(),
           let typedResult = anyResult as? Q.Result
        {
            return typedResult
        }

        if activeRequests.contains(key) {
            throw CycleRequestError(request: request)
        }

        activeRequests.append(key)
        let typedResult = Result<Q.Result, Swift.Error> {
            try request.evaluate(on: self)
        }
        self.resultCache[key] = typedResult.map { $0 as Any }
        activeRequests.remove(key)
        return try typedResult.get()
    }
}
