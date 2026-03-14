import SwiftUI

enum ANSIParser {
    struct StyledRun: Sendable {
        let text: String
        let foreground: Color?
        let bold: Bool
    }

    static func parse(_ input: String) -> [StyledRun] {
        var runs: [StyledRun] = []
        var current = ""
        var fg: Color? = nil
        var bold = false

        var i = input.startIndex
        while i < input.endIndex {
            if input[i] == "\u{1B}", input.index(after: i) < input.endIndex,
               input[input.index(after: i)] == "[" {
                if !current.isEmpty {
                    runs.append(StyledRun(text: current, foreground: fg, bold: bold))
                    current = ""
                }
                let seqStart = input.index(i, offsetBy: 2)
                var seqEnd = seqStart
                while seqEnd < input.endIndex {
                    let c = input[seqEnd]
                    if c.isLetter || c == "m" { break }
                    seqEnd = input.index(after: seqEnd)
                }
                if seqEnd < input.endIndex {
                    let codes = input[seqStart..<seqEnd]
                        .split(separator: ";")
                        .compactMap { Int($0) }
                    for code in codes.isEmpty ? [0] : codes {
                        switch code {
                        case 0: fg = nil; bold = false
                        case 1: bold = true
                        case 22: bold = false
                        case 30: fg = .black
                        case 31: fg = .red
                        case 32: fg = .green
                        case 33: fg = .yellow
                        case 34: fg = .blue
                        case 35: fg = .purple
                        case 36: fg = .cyan
                        case 37: fg = .white
                        case 39: fg = nil
                        case 90: fg = .gray
                        case 91: fg = .red
                        case 92: fg = .green
                        case 93: fg = .yellow
                        case 94: fg = .blue
                        case 95: fg = .purple
                        case 96: fg = .cyan
                        case 97: fg = .white
                        default: break
                        }
                    }
                    i = input.index(after: seqEnd)
                } else {
                    current.append(input[i])
                    i = input.index(after: i)
                }
            } else {
                current.append(input[i])
                i = input.index(after: i)
            }
        }
        if !current.isEmpty {
            runs.append(StyledRun(text: current, foreground: fg, bold: bold))
        }
        return runs
    }

    static func styledText(from input: String) -> Text {
        let runs = parse(input)
        if runs.isEmpty { return Text("") }
        return runs.reduce(Text("")) { result, run in
            var t = Text(run.text)
            if let fg = run.foreground { t = t.foregroundColor(fg) }
            if run.bold { t = t.bold() }
            return result + t
        }
    }
}
