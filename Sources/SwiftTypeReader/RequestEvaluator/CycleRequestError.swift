public struct CycleRequestError: Error & CustomStringConvertible {
    public init(request: any Request) {
        self.description = "request cycle detected: \(request)"
    }

    public var description: String
}
