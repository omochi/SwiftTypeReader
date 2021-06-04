extension Optional {
    mutating func ensure(_ f: () throws -> Wrapped) rethrows -> Wrapped {
        if let x = self { return x }
        let x = try f()
        self = x
        return x
    }
}
