public protocol _DeclParentContextHolder {
    var context: (any DeclContext)? { get }
}

extension _DeclParentContextHolder {
    var rootContext: Context {
        if let parent = context {
            return parent.rootContext
        }

        if let module = self as? ModuleDecl {
            return module._context
        }

        fatalError("invalid decl \(self)")
    }
}
