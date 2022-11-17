public protocol DeclContext: AnyObject & Hashable & _DeclParentContextHolder {
    func find(name: String, options: LookupOptions) -> any Decl
}

extension DeclContext {
    public static func ==(a: Self, b: Self) -> Bool {
        a === b
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public func asAnyDeclContext() -> AnyDeclContext {
        AnyDeclContext(self)
    }
}
