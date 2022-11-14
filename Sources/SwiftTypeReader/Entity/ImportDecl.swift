import Foundation

public struct ImportDecl {
    public unowned var module: Module
    public var file: URL?
    public var location: Location
    public enum Target {
        case module(name: String)
    }
    public var target: Target

    public init(module: Module, file: URL?, location: Location, target: Target) {
        self.module = module
        self.file = file
        self.location = location
        self.target = target
    }

    public var name: String {
        switch target {
        case .module(let name):
            return name
        }
    }
}
