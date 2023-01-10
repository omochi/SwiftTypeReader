import Foundation

extension FileManager {
    func enumerateRelative(
        path: URL,
        options: Set<EnumerateRelativePath.Option>
    ) -> EnumerateRelativePath {
        return EnumerateRelativePath(fileManager: self, base: path, options: options)
    }
}

struct EnumerateRelativePath: Sequence {
    enum Option {
        case skipsHiddenFiles
    }

    typealias Element = URL

    var fileManager: FileManager
    var base: URL
    var options: Set<Option>

    struct Iterator: IteratorProtocol {
        var sequence: EnumerateRelativePath
        var enumerator: FileManager.DirectoryEnumerator?

        func next() -> URL? {
            guard let enumerator else { return nil }

            while true {
                guard let path = enumerator.nextObject() as? String else { return nil }

                if sequence.options.contains(.skipsHiddenFiles), path.hasPrefix(".") {
                    continue
                }

                return URL(fileURLWithPath: path, relativeTo: sequence.base)
            }
        }
    }

    func makeIterator() -> Iterator {
        return Iterator(
            sequence: self,
            enumerator: fileManager.enumerator(atPath: base.relativePath)
        )
    }
}
