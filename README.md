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

# Development

## Design consideration

This library doesn't distinguish type descriptor and concrete type.
It make implementation simple but ugly especially when generic argument application happens.

# Unsupported language features

## Class

```swift
class C {}
```

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
