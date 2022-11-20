public struct MetatypeType: SType {
    public init(
        instance: any SType
    ) {
        self.instance = instance
    }

    @AnyTypeStorage public var instance: any SType
}
