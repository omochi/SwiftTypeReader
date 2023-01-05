# SwiftTypeReader

You can gather type definitions from Swift source code.

## Example

```swift
    func testReadmeExample() throws {
        try withExtendedLifetime(Context()) { (context) in
            let module = context.getOrCreateModule(name: "main")
            let reader = Reader(context: context, module: module)

            let source = try reader.read(
                source: """
struct S {
    var a: Int?
}
""",
                file: URL(fileURLWithPath: "S.swift")
            )
            _ = source

            let s = try XCTUnwrap(module.find(name: "S")?.asStruct)
            XCTAssertEqual(s.name, "S")

            XCTAssertEqual(s.storedProperties.count, 1)
            let a = try XCTUnwrap(s.find(name: "a")?.asVar)
            XCTAssertIdentical(a, s.storedProperties[safe: 0])
            XCTAssertEqual(a.name, "a")

            let aType = try XCTUnwrap(a.interfaceType.asEnum)
            XCTAssertEqual(aType.name, "Optional")
            XCTAssertEqual(aType.genericArgs.count, 1)

            let aWrappedType = try XCTUnwrap(aType.genericArgs[safe: 0]?.asStruct)
            XCTAssertEqual(aWrappedType.name, "Int")
        }
    }
```

## More documents

- [Version 2 Guide](https://github.com/omochi/SwiftTypeReader/blob/main/Docs/v2-migration-guide.md)

# Unsupported language features

## Function body

It handles only signature.

## Generic signatures of function

## Variable without type annotation

```swift
struct S {
    var a = 0
}
```

It doesn't have type inference.

# Vision

This library focus to use for building other libraries below.

- [CodableToTypeScript](https://github.com/omochi/CodableToTypeScript): Swift type transpiler for TypeScript by me.
- [CallableKit](https://github.com/sidepelican/CallableKit): Swift RPC bridge for TypeScript by iceman.

But It's useful in standalone for other purpose like meta programming for Swift.

# Development

## Design consideration

This library refer to the Swift compiler and [Slava's book](https://forums.swift.org/t/compiling-swift-generics-part-i/60898) to build architecture.
It provides *decls*, *types*, and *type reprs*.

## Code generation

```
$ swift package codegen
```
