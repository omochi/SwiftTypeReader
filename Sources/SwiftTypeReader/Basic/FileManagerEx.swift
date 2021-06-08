import Foundation

extension FileManager {
    // This iterator builds nice URL.relativePath

    private struct DOFIterator: IteratorProtocol {
        var fm: FileManager
        var url: URL
        var keys: [URLResourceKey]?
        var options: DirectoryEnumerationOptions

        var stack: [URL]

        mutating func next() -> URL? {
            while true {
                guard let head = stack.first else {
                    return nil
                }
                stack.removeFirst()

                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: head.path, isDirectory: &isDir) else {
                    continue
                }

                guard isDir.boolValue else {
                    return head
                }

                if let files = try? fm.contentsOfDirectory(
                    at: head,
                    includingPropertiesForKeys: keys,
                    options: options
                ) {
                    stack += files.map { (file) in
                        head.appendingPathComponent(file.lastPathComponent)
                    }
                }

                return head
            }
        }
    }

    func directoryOrFileEnumerator(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]? = nil,
        options: DirectoryEnumerationOptions = []
    ) -> AnySequence<URL> {
        return AnySequence { () in
            return DOFIterator(
                fm: self,
                url: url,
                keys: keys,
                options: options,
                stack: [url]
            )
        }
    }

}
