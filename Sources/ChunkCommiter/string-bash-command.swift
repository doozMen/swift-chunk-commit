import Foundation
import Logging

public enum CLIConfig {
  @TaskLocal public static var cwd: String?
}

private let logger = Logger(label: "chunk-commit:bash+string")

extension String {

  @discardableResult
  public func run() async throws -> String {
    logger.trace("\u{001B}[0;32m\(self)\u{001B}[0m - [cwd: \(CLIConfig.cwd ?? "nil")]")
    return try await Task {
      return try runBashCommand(self, cwd: CLIConfig.cwd)
    }.value
  }
}

@discardableResult
private func runBashCommand(_ command: String, cwd: String?) throws -> String {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["bash", "-c", command]
  process.currentDirectoryPath = cwd ?? FileManager.default.currentDirectoryPath

  let pipe = Pipe()
  process.standardOutput = pipe
  process.standardError = pipe

  do {
    try process.run()
    process.waitUntilExit()
  } catch {
    throw ChunkCommitterError.cliCommandFailed(forCommand: command, error: error)
  }

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  guard let output = String(data: data, encoding: .utf8) else {
    throw ChunkCommitterError.cliCommandFailed(forCommand: command)
  }

  if process.terminationStatus != EXIT_SUCCESS {
    throw ChunkCommitterError.bash(command: command, output: output)
  }

  return output.trimmingCharacters(in: .whitespacesAndNewlines)
}
