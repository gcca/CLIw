import Foundation

struct SnippetEntry: Identifiable, Hashable, Sendable {
    let filename: String
    let displayName: String

    var id: String { filename }

    init(filename: String) {
        self.filename = filename
        self.displayName = filename
            .replacingOccurrences(of: ".json", with: "")
            .split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

struct Snippet: Codable, Identifiable, Hashable, Sendable {
    var title: String
    var description: String
    var command: String
    var arguments: [Argument]

    var id: String { title }

    struct Argument: Codable, Hashable, Sendable, Identifiable {
        var long: String?
        var short: String?
        var type: ArgumentType
        var `default`: ArgumentValue?
        var choices: [ArgumentValue]?

        var id: String { long ?? short ?? UUID().uuidString }

        var displayName: String {
            long ?? short ?? "arg"
        }
    }

    enum ArgumentType: String, Codable, Sendable {
        case string
        case integer
        case float
        case boolean
    }

    enum ArgumentValue: Codable, Hashable, Sendable {
        case string(String)
        case integer(Int)
        case float(Double)
        case boolean(Bool)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let v = try? container.decode(Bool.self) {
                self = .boolean(v)
            } else if let v = try? container.decode(Int.self) {
                self = .integer(v)
            } else if let v = try? container.decode(Double.self) {
                self = .float(v)
            } else {
                self = .string(try container.decode(String.self))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let v): try container.encode(v)
            case .integer(let v): try container.encode(v)
            case .float(let v): try container.encode(v)
            case .boolean(let v): try container.encode(v)
            }
        }

        var displayString: String {
            switch self {
            case .string(let v): v
            case .integer(let v): "\(v)"
            case .float(let v): "\(v)"
            case .boolean(let v): "\(v)"
            }
        }
    }
}
