import Foundation
import CodegenKit

@main
struct Codegen {
    static func main() throws {
        try Codegen().run()
    }

    init() {
        let defs = Definitions()
        self.definitions = defs
        self.runner = CodegenRunner(renderers: [
            BaseTypeRenderer(defs: defs),
            TypeTransformerRenderer(defs: defs)
        ])
    }

    var definitions: Definitions
    var runner: CodegenRunner

    func run() throws {
        var args = CommandLine.arguments
        args.removeFirst()
        guard let sourcesDirString = args.first else {
            throw MessageError("no sources dir")
        }
        args.removeFirst()
        let sourcesDir = URL(fileURLWithPath: sourcesDirString)

        try runner.run(directories: [sourcesDir])
    }
}
