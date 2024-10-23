import ArgumentParser
import Foundation
import Logging
import CLILogger

private let logger = Logger(label: "chunk-commit")

package struct Chunk: AsyncParsableCommand {
  @Argument(help: "Define the target branch where you want to cherry-pick the commits")
  private var targetBranch: String
  @Option private var cwd: String?
  @OptionGroup private var logLevelOptions: LogLevelOptions

  package init() {}

  package func run() async throws {
    try await chunk(onto: targetBranch, cwd: cwd)

    
  }
}

public func chunk(onto targetBranch: String, cwd: String? = CLIConfig.cwd) async throws {
  try await CLIConfig.$cwd.withValue(cwd) {
    try await _chunk(targetBranch)
  }
}

fileprivate func _chunk(_ targetBranch: String) async throws {
  logger.notice("🪚 chunking commits ...")
  let branch = try await "git rev-parse --abbrev-ref HEAD".run()
  
  logger.trace("starting from branch \(branch)")
  
  logger.trace("gettting list of files")
  // Get the list of tracked and untracked files
  let filesArray = try await
  "git ls-files --others --exclude-standard; git diff --name-only HEAD".run().components(separatedBy: "\n")
  
  logger.trace("Found \(filesArray.count) changed files: [\(filesArray.joined(separator: ", "))]")
  
  var commitHashes: [String] = []
  
  // Loop over the files and commit them in chunks of max 10 files
  for i in stride(from: 0, to: filesArray.count, by: 10) {
    let chunk = Array(filesArray[i..<min(i + 10, filesArray.count)])
    let commitMsg = "Chunked commit \(commitHashes.count + 1)"
    
    // Commit the chunk and store the commit hash
    let commitHash = try await commitFiles(chunk, commitMessage: commitMsg)
    commitHashes.append(commitHash)
  }
  
  logger.trace("Checking out target branch (\(targetBranch)) if needed.")
  if branch.trimmingCharacters(in: .whitespacesAndNewlines) != targetBranch {
    try await "git checkout \(targetBranch)".run()
  }
  
  logger.trace("Cherry-pick each of the chunked commits using the stored hashes")
  for commitHash in commitHashes {
    do {
      try await "git cherry-pick \(commitHash)".run()
    } catch {
      throw ChunkCommitterError.cherryPickError(commitHash: commitHash)
    }
  }
  
  logger.notice("✅ 🪚 chunking commits - cherry-picked onto \(targetBranch).")
}
