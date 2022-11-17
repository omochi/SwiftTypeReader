public struct MetatypeType: SType2 {
    public init(
        instance: some SType2
    ) {
        self.instance = instance.asAnyType()
    }

    public var instance: AnyType

    public var description: String {
        "\(instance).Type"
    }
}
