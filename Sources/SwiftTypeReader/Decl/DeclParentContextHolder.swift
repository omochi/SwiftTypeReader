public protocol _DeclParentContextHolder {
    var context: (any DeclContext)? { get }
}

extension _DeclParentContextHolder {
    public var moduleContext: ModuleDecl {
        if let module = self as? ModuleDecl {
            return module
        }

        if let parent = context {
            return parent.moduleContext
        }

        fatalError("invalid decl \(self)")
    }

    public var rootContext: Context {
        moduleContext._context
    }
}
