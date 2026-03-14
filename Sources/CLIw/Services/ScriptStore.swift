import Foundation
import Observation

@Observable
@MainActor
final class ScriptStore {
    private(set) var entries: [SnippetEntry] = []
    private var cache: [String: Snippet] = [:]
    private let scriptsURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        scriptsURL = appSupport
            .appendingPathComponent("CLIw", isDirectory: true)
            .appendingPathComponent("scripts", isDirectory: true)
        ensureDirectory()
        if directoryIsEmpty() {
            seedSamples()
        }
        loadIndex()
    }

    func loadIndex() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: scriptsURL,
            includingPropertiesForKeys: nil
        ) else { return }

        entries = files
            .filter { $0.pathExtension == "json" }
            .map { SnippetEntry(filename: $0.lastPathComponent) }
            .sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
    }

    func snippet(for entry: SnippetEntry) -> Snippet? {
        if let cached = cache[entry.filename] {
            return cached
        }
        let url = scriptsURL.appendingPathComponent(entry.filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let snippet = try? JSONDecoder().decode(Snippet.self, from: data) else { return nil }
        cache[entry.filename] = snippet
        return snippet
    }

    func save(_ snippet: Snippet) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snippet)
        let name = filename(for: snippet)
        let fileURL = scriptsURL.appendingPathComponent(name)
        try data.write(to: fileURL, options: .atomic)
        cache[name] = snippet
        loadIndex()
    }

    func delete(_ entry: SnippetEntry) throws {
        let fileURL = scriptsURL.appendingPathComponent(entry.filename)
        try FileManager.default.removeItem(at: fileURL)
        cache.removeValue(forKey: entry.filename)
        loadIndex()
    }

    private func filename(for snippet: Snippet) -> String {
        let safe = snippet.title
            .lowercased()
            .replacing(/[^a-z0-9]+/, with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return "\(safe).json"
    }

    private func ensureDirectory() {
        try? FileManager.default.createDirectory(
            at: scriptsURL,
            withIntermediateDirectories: true
        )
    }

    private func directoryIsEmpty() -> Bool {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: scriptsURL,
            includingPropertiesForKeys: nil
        )) ?? []
        return !files.contains { $0.pathExtension == "json" }
    }

    private func seedSamples() {
        let samples: [Snippet] = [
            Snippet(
                title: "Git Status",
                description: "Show working tree status",
                command: "git status",
                arguments: [
                    .init(long: "--short", short: "-s", type: .boolean, default: .boolean(false)),
                    .init(long: "--branch", short: "-b", type: .boolean, default: .boolean(true)),
                ]
            ),
            Snippet(
                title: "Git Log",
                description: "Show commit history",
                command: "git log",
                arguments: [
                    .init(long: "--oneline", short: nil, type: .boolean, default: .boolean(true)),
                    .init(long: "--graph", short: nil, type: .boolean, default: .boolean(false)),
                    .init(long: "--all", short: nil, type: .boolean, default: .boolean(false)),
                    .init(long: "-n", short: nil, type: .integer, default: .integer(20)),
                ]
            ),
            Snippet(
                title: "Brew Update",
                description: "Fetch newest version of Homebrew and formulae",
                command: "brew update",
                arguments: [
                    .init(long: "--verbose", short: nil, type: .boolean, default: .boolean(false)),
                    .init(long: "--force", short: nil, type: .boolean, default: .boolean(false)),
                ]
            ),
            Snippet(
                title: "Brew List",
                description: "List installed formulae and casks",
                command: "brew list",
                arguments: [
                    .init(long: "--formula", short: nil, type: .boolean, default: .boolean(false)),
                    .init(long: "--cask", short: nil, type: .boolean, default: .boolean(false)),
                    .init(long: "--versions", short: nil, type: .boolean, default: .boolean(false)),
                ]
            ),
            Snippet(
                title: "Curl",
                description: "Transfer data from a URL",
                command: "curl",
                arguments: [
                    .init(long: "--silent", short: "-s", type: .boolean, default: .boolean(false)),
                    .init(long: "--location", short: "-L", type: .boolean, default: .boolean(true)),
                    .init(long: "--output", short: "-o", type: .string),
                    .init(long: "--max-time", short: nil, type: .float, default: .float(30.0)),
                    .init(long: nil, short: nil, type: .string, default: .string("https://example.com")),
                ]
            ),
            Snippet(
                title: "List Files",
                description: "List directory contents",
                command: "ls",
                arguments: [
                    .init(long: nil, short: "-l", type: .boolean, default: .boolean(true)),
                    .init(long: nil, short: "-a", type: .boolean, default: .boolean(false)),
                    .init(long: nil, short: "-h", type: .boolean, default: .boolean(true)),
                    .init(
                        long: "--sort", short: nil, type: .string, default: .string("name"),
                        choices: [.string("name"), .string("size"), .string("time")]
                    ),
                    .init(long: nil, short: nil, type: .string, default: .string(".")),
                ]
            ),
            Snippet(
                title: "Cat",
                description: "Display file contents",
                command: "cat",
                arguments: [
                    .init(long: nil, short: "-n", type: .boolean, default: .boolean(false)),
                    .init(long: nil, short: "-e", type: .boolean, default: .boolean(false)),
                    .init(long: nil, short: nil, type: .string),
                ]
            ),
            Snippet(
                title: "Ping",
                description: "Ping a network host",
                command: "ping",
                arguments: [
                    .init(long: nil, short: "-c", type: .integer, default: .integer(4)),
                    .init(long: nil, short: "-i", type: .float, default: .float(1.0)),
                    .init(long: nil, short: nil, type: .string, default: .string("1.1.1.1")),
                ]
            ),
            Snippet(
                title: "Disk Usage",
                description: "Show disk space usage",
                command: "df",
                arguments: [
                    .init(long: nil, short: "-h", type: .boolean, default: .boolean(true)),
                ]
            ),
            Snippet(
                title: "Process Status",
                description: "Show running processes",
                command: "ps",
                arguments: [
                    .init(long: nil, short: nil, type: .string, default: .string("aux")),
                ]
            ),
            Snippet(
                title: "Docker PS",
                description: "List Docker containers",
                command: "docker ps",
                arguments: [
                    .init(long: "--all", short: "-a", type: .boolean, default: .boolean(false)),
                    .init(long: "--quiet", short: "-q", type: .boolean, default: .boolean(false)),
                    .init(long: "--format", short: nil, type: .string, default: .string("table")),
                    .init(long: "-n", short: nil, type: .integer),
                ]
            ),
        ]
        for s in samples {
            try? save(s)
        }
    }
}
