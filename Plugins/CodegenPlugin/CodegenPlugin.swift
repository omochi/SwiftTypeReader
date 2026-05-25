import Foundation
import PackagePlugin

@main
struct CodegenPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let codegen = try context.tool(named: "codegen")

        let sourcesDir = context.package.directoryURL.appending(path: "Sources")

        let process = EasyProcess(
            path: codegen.url,
            args: [sourcesDir.path(percentEncoded: false)]
        )
        try process.run()
    }
}
