import Foundation
import PackagePlugin

@main
struct CodegenPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let codegen = try context.tool(named: "codegen")

        let sourcesDir = context.package.directory.appending(subpath: "Sources")

        let process = EasyProcess(
            path: URL(fileURLWithPath: codegen.path.string),
            args: [sourcesDir.string]
        )
        try process.run()
    }
}
