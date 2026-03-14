import Foundation
import Observation

@Observable
@MainActor
final class CommandRunner {
    enum Status: Sendable {
        case idle
        case running
        case finished(exitCode: Int32)
        case failed(String)
    }

    struct OutputLine: Identifiable, Sendable {
        let id: UUID
        let text: String
        let isStderr: Bool
    }

    private(set) var status: Status = .idle
    private(set) var outputLines: [OutputLine] = []
    @ObservationIgnored private var currentProcess: Process?

    func run(command: String) async {
        status = .running
        outputLines = []
        currentProcess = nil

        let (stream, continuation) = AsyncStream<OutputLine>.makeStream()

        let task = Task.detached { [command] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", command]
            process.environment = ProcessInfo.processInfo.environment

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
                for line in str.components(separatedBy: "\n") {
                    continuation.yield(OutputLine(id: UUID(), text: line, isStderr: false))
                }
            }

            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
                for line in str.components(separatedBy: "\n") {
                    continuation.yield(OutputLine(id: UUID(), text: line, isStderr: true))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.finish()
                return -1 as Int32
            }

            await MainActor.run { [process] in
                self.currentProcess = process
            }

            process.waitUntilExit()

            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            continuation.finish()

            return process.terminationStatus
        }

        for await line in stream {
            outputLines.append(line)
        }

        let exitCode = await task.value
        status = .finished(exitCode: exitCode)
        currentProcess = nil
    }

    func cancel() {
        currentProcess?.terminate()
        currentProcess = nil
    }
}
