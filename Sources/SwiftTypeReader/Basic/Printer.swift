import Foundation

struct Printer {
    static func genericClause(_ items: [String]) -> String {
        if items.isEmpty { return "" }
        
        var s = ""
        s += "<"
        s += items.joined(separator: ", ")
        s += ">"
        return s
    }
}
