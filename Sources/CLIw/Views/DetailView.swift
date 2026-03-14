import SwiftUI

struct DetailView: View {
    let snippet: Snippet
    @State private var formState: ArgumentFormState
    @State private var runner = CommandRunner()

    init(snippet: Snippet) {
        self.snippet = snippet
        self._formState = State(initialValue: ArgumentFormState(arguments: snippet.arguments))
    }

    var body: some View {
        VSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    Divider()
                    commandSection
                    if !formState.entries.isEmpty {
                        argumentsForm
                    }
                }
                .padding()
            }

            OutputView(runner: runner)
                .padding(8)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "terminal")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading) {
                Text(snippet.title)
                    .font(.title2.bold())
                if !snippet.description.isEmpty {
                    Text(snippet.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if case .running = runner.status {
                Button("Stop", role: .destructive) {
                    runner.cancel()
                }
            }
            Button("Run") {
                let command = formState.buildCommandLine(for: snippet)
                Task { await runner.run(command: command) }
            }
            .buttonStyle(.borderedProminent)
            .disabled({
                if case .running = runner.status { return true }
                return false
            }())
        }
    }

    private var commandSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Command")
                .font(.headline)
            Text(formState.buildCommandLine(for: snippet))
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .textSelection(.enabled)
        }
    }

    private var argumentsForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Arguments")
                .font(.headline)
            ForEach($formState.entries) { $entry in
                ArgumentFormRow(entry: $entry)
            }
        }
    }
}

private struct ArgumentFormRow: View {
    @Binding var entry: ArgumentFormState.Entry

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.argument.displayName)
                .font(.system(.body, design: .monospaced))
                .frame(width: 120, alignment: .leading)

            control

            Text(entry.argument.type.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var control: some View {
        switch entry.argument.type {
        case .boolean:
            Toggle("", isOn: $entry.boolValue)
                .labelsHidden()
            Spacer()

        case .string:
            if let choices = entry.argument.choices, !choices.isEmpty {
                Picker("", selection: $entry.stringValue) {
                    ForEach(choices, id: \.displayString) { choice in
                        Text(choice.displayString).tag(choice.displayString)
                    }
                }
                .labelsHidden()
                Spacer()
            } else {
                TextField("value", text: $entry.stringValue)
                    .textFieldStyle(.roundedBorder)
            }

        case .integer:
            TextField("0", text: $entry.stringValue)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
            Spacer()

        case .float:
            TextField("0.0", text: $entry.stringValue)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
            Spacer()
        }
    }
}
