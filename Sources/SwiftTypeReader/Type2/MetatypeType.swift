public struct MetatypeType: SType2 {
    public init(
        instance: any SType2
    ) {
        self.instance = instance
    }

    @AnyTypeStorage public var instance: any SType2

    public var description: String {
        toTypeRepr(containsModule: false).description
    }
}
