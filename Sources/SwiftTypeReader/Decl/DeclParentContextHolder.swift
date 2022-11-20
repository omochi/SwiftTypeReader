public protocol _DeclParentContextHolder {
    var parentContext: (any DeclContext)? { get }
}

extension _DeclParentContextHolder {
    public var moduleContext: Module {
        if let module = self as? Module {
            return module
        }

        if let parent = parentContext {
            return parent.moduleContext
        }

        fatalError("invalid decl \(self)")
    }

    public var rootContext: Context {
        moduleContext.context
    }
}
