import SwiftSyntax

struct ModifierReader {
    var modifiers: [DeclModifier] = []

    mutating func read(token: TokenSyntax) {
        guard let modifier = DeclModifier(rawValue: token.text) else { return }
        modifiers.append(modifier)
    }

    mutating func read(token: TokenSyntax?) {
        guard let token else { return }
        read(token: token)
    }

    mutating func read(decl: DeclModifierSyntax) {
        read(token: decl.name)
    }

    mutating func read(decl: DeclModifierSyntax?) {
        guard let decl else { return }
        read(decl: decl)
    }

    mutating func read(decls: DeclModifierListSyntax) {
        for decl in decls {
            read(decl: decl)
        }
    }

    mutating func read(decls: DeclModifierListSyntax?) {
        guard let decls else { return }
        read(decls: decls)
    }
}
