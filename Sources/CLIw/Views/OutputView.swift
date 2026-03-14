import SwiftUI

struct OutputView: View {
    let runner: CommandRunner

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusBar
            Divider()
            scrollableOutput
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary)
        )
    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            switch runner.status {
            case .idle:
                Image(systemName: "terminal")
                    .foregroundStyle(.secondary)
                Text("Ready")
                    .foregroundStyle(.secondary)
            case .running:
                ProgressView()
                    .controlSize(.small)
                Text("Running...")
            case .finished(let code):
                Image(systemName: code == 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(code == 0 ? .green : .red)
                Text("Exit code: \(code)")
                    .foregroundStyle(code == 0 ? Color.primary : Color.red)
            case .failed(let msg):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(msg)
                    .foregroundStyle(.red)
            }
            Spacer()
            if !runner.outputLines.isEmpty {
                Text("\(runner.outputLines.count) lines")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var scrollableOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(runner.outputLines) { line in
                        outputRow(line)
                            .id(line.id)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: runner.outputLines.count) {
                if let last = runner.outputLines.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
        .frame(minHeight: 120, maxHeight: .infinity)
        .font(.system(.caption, design: .monospaced))
    }

    private func outputRow(_ line: CommandRunner.OutputLine) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if line.isStderr {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption2)
            }
            ANSIParser.styledText(from: line.text)
        }
        .padding(.vertical, 1)
    }
}
