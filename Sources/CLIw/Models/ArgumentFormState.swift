import Foundation
import Observation

@Observable
@MainActor
final class ArgumentFormState {
    var entries: [Entry]

    struct Entry: Identifiable {
        let id: String
        let argument: Snippet.Argument
        var stringValue: String
        var boolValue: Bool
    }

    init(arguments: [Snippet.Argument]) {
        entries = arguments.map { arg in
            let id = arg.long ?? arg.short ?? UUID().uuidString
            switch arg.type {
            case .boolean:
                let on: Bool
                if case .boolean(let v) = arg.default { on = v } else { on = false }
                return Entry(id: id, argument: arg, stringValue: "", boolValue: on)
            case .string:
                let v: String
                if case .string(let s) = arg.default { v = s } else { v = "" }
                return Entry(id: id, argument: arg, stringValue: v, boolValue: false)
            case .integer:
                let v: String
                if case .integer(let n) = arg.default { v = "\(n)" } else { v = "" }
                return Entry(id: id, argument: arg, stringValue: v, boolValue: false)
            case .float:
                let v: String
                if case .float(let n) = arg.default { v = "\(n)" } else { v = "" }
                return Entry(id: id, argument: arg, stringValue: v, boolValue: false)
            }
        }
    }

    func buildCommandLine(for snippet: Snippet) -> String {
        var parts: [String] = [snippet.command]
        for entry in entries {
            let arg = entry.argument
            let flag = arg.short ?? arg.long
            let isPositional = arg.long == nil && arg.short == nil

            switch arg.type {
            case .boolean:
                if entry.boolValue, let flag {
                    parts.append(flag)
                }
            case .string, .integer, .float:
                let val = entry.stringValue.trimmingCharacters(in: .whitespaces)
                guard !val.isEmpty else { continue }
                if isPositional {
                    parts.append(val)
                } else if let flag {
                    parts.append(flag)
                    parts.append(val)
                }
            }
        }
        return parts.joined(separator: " ")
    }
}
