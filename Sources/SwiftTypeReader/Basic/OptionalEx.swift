extension Optional {
    func toArray() -> Array<Wrapped> {
        guard let self else { return [] }
        return [self]
    }
}
