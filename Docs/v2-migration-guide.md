# バージョン2への移行ガイド

# Declの導入

Declという概念を導入しました。
これはソースコード上の宣言やデータ構造に対応付いたエンティティです。
コード中でなにかのシンボルを書いた時、それが指し示す対象です。

従来は型を `SType` で表現していましたが、
型そのものを現す `SType` と、型を定義する宣言を現す `Decl` が分離されました。

例えばジェネリック型 `S<T>` と、その具象化された `S<Int>` と `S<String>` を考える事ができます。
このとき、 `S<T>` は共通の一つの `StructDecl` で表され、ジェネリック型パラメータ `T` はここに定義されます。
そして、 `S<Int>` と `S<String>` はそれぞれ異なる `StructType` で表され、ジェネリック型引数はそれぞれが保持します。

## VarDeclの導入

Stored property は `VarDecl` で表現する事にしました。
これはローカル変数やcomputed propertyなどの `var` と共通化された表現です。

## interface type と declared interface type

以下のコードを例に説明します。

```swift
struct S {
  var a: Int
}
```

interface typeは、その `Decl` を式として参照した時の型です。
例えば、 `S` のプロパティ `a` の interface type は `Int` です。
一方、`S` の interface type は `S` ではなく、そのメタタイプの `S.Type` です。

declared interface typeは、`TypeDecl` が定義する型です。
例えば、 `S` の declared interface type は `S` です。

# Typeツリーの見直し

`SType` は `enum` から `protocol` に変更され、
ほとんど全てのプロパティが除去されました。
型についてなにか操作を行いたい場合、 `any NominalType` や `StructType` に `as?` でダウンキャストしてください。

型の名前は `NominalType` から `NominalTypeDecl` を参照し、そこから `name` として取得できます。
`SType` が名前すら持っていないのは、型には `(Int) -> Int` のような関数型など、名前を持たないものもあるからです。

# TypeReprの導入

型を参照するコードは `TypeRepr` として表現されます。
従来は `TypeSpecifier` でしたが本家コンパイラに命名を寄せました。
そして、ダウンキャストして扱うように変更されました。
これもソースコード文法と対応して、`P & Q` や `(Int) -> Int` など、アイデンティティのドット区切りでは表現できない記述があるためです。

`TypeRepr` は例えば `VarDecl` の型定義部分として保持されていて、
`resolve` メソッドで `SType` に変換する事ができます。

## ErrorType

型の取得がなんらかの問題を生じた場合、 `ErrorType` になります。
もし `TypeRepr` を解決しようとしたが定義が見つからなかった場合は、 `ErrorType.repr` で元の `TypeRepr` を参照できます。
従来は `UnresolvedType` としていましたが、これは本家コンパイラで、別の用途で命名されているので避けました。
また、本家を参考に、定義不明以外の状況にも汎用化しました。

# DeclContextの導入

`DeclContext` は自身の子として `Decl` を保持するオブジェクトです。
これにより `DeclContext` はツリー構造を構築します。
`Decl` は自身の親 `DeclContext` を参照しています。

`Module` や `StructDecl` は、メンバを持てるので、 `Decl` であると同時に `DeclContext` です。 

`Decl` ではあるが、 `DeclContext` ではないものとして、
`var` を表す `VarDecl` や、ジェネリック型パラメータを表す `GenericParamDecl` があります。

`Decl` ではないが、 `DeclContext` ではあるものとして、
クロージャ式などがありますが、ここでは未実装です。

## DeclContext.find

`DeclContext` のメンバを名前で探すメソッドとして `find` があり、便利です。
テストケースをこれで書き換えているので参考にしてください。

# Locationの廃止

従来の `Location` はあるエンティティがソースの意味構造において、
どこに所属するものかを表現するパスデータでした。
これは値型を多用したデータ構造において、アイデンティティを取り扱うために必要でした。
また、ツリー構造を巡回するために、
親に登るために `Location` の末尾を切り捨てる操作などが必要でした。

新しい設計では、 `Decl` がクラスでアイデンティティを持ち、
ツリー構造を形成しています。
また、 `Decl` は自身の親への参照を持っています。
よって、ある `Decl` はそれ自身がツリーにおける場所も表現しています。

場所の同一性判定も、単に `Decl` を同値比較する事で行なえます。

以上のように `Location` の必要性が解消したので廃止しました。

