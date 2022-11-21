public struct CycleRequestError: Error & CustomStringConvertible {
    public var request: any Request

    public init(request: any Request) {
        self.request = request
    }

    public var description: String {
        return "request cycle detected: \(request)"
    }
}
