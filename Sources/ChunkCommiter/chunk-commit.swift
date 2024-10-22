import ArgumentParser
import Foundation

package struct Chunk: AsyncParsableCommand {
  @Argument(help: "Define the target branch where you want to cherry-pick the commits")
  private var targetBranch: String
  @Option private var cwd: String?

  package init() {}

  package func run() async throws {
    try await chunk(onto: targetBranch, cwd: cwd)
  }
}

public func chunk(onto targetBranch: String, cwd: String?) async throws {
  try await GitConfig.$cwd.withValue(cwd) {
    try await _chunk(onto: targetBranch, cwd: cwd)
  }
}

private func _chunk(onto targetBranch: String, cwd: String?) async throws {  // Ensure you're on a detached HEAD
  let branch = try await "git rev-parse --abbrev-ref HEAD".run()
  if branch != "HEAD" {
    throw GitScriptError.notDetachedHead
  }

  // Get the list of tracked and untracked files
  guard
    let filesOutput = try? await
      "git ls-files --others --exclude-standard; git diff --name-only HEAD".run()
  else {
    throw GitScriptError.fileFetchError
  }

  let filesArray = filesOutput.split(separator: "\n").map { String($0) }
  let fileCount = filesArray.count
  var commitHashes: [String] = []

  // Loop over the files and commit them in chunks of max 10 files
  for i in stride(from: 0, to: fileCount, by: 10) {
    let chunk = Array(filesArray[i..<min(i + 10, fileCount)])
    let commitMsg = "Chunked commit \(commitHashes.count + 1)"

    // Commit the chunk and store the commit hash
    let commitHash = try await commitFiles(chunk, commitMessage: commitMsg)
    commitHashes.append(commitHash)
  }

  // Switch to the target branch
  try await "git checkout \(targetBranch)".run()

  // Cherry-pick each of the chunked commits using the stored hashes
  for commitHash in commitHashes {
    do {
      try await "git cherry-pick \(commitHash)".run()
    } catch {
      throw GitScriptError.cherryPickError(commitHash: commitHash)
    }
  }

  print("Successfully chunked commits and cherry-picked them to \(targetBranch).")
}
