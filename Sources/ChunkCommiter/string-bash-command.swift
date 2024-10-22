import Foundation

enum GitConfig {
  @TaskLocal static var cwd: String?
}

extension String {

  @discardableResult
  func run() async throws -> String {
    try await Task {
      try runBashCommand(self, cwd: GitConfig.cwd ?? FileManager.default.currentDirectoryPath)
    }.value
  }
}

// Function to run git commands and capture their output
@discardableResult
func runBashCommand(_ command: String, cwd: String) throws -> String {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["bash", "-c", command]
  process.currentDirectoryPath = cwd

  let pipe = Pipe()
  process.standardOutput = pipe
  process.standardError = pipe

  do {
    try process.run()
    process.waitUntilExit()
  } catch {
    throw GitScriptError.fileFetchError
  }

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  guard let output = String(data: data, encoding: .utf8) else {
    throw GitScriptError.fileFetchError
  }

  return output.trimmingCharacters(in: .whitespacesAndNewlines)
}
