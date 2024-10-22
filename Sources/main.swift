import Foundation

// Define errors that can occur during the script execution
enum GitScriptError: Error, CustomStringConvertible {
  case notDetachedHead
  case fileFetchError
  case commitError
  case cherryPickError(commitHash: String)

  var description: String {
    switch self {
    case .notDetachedHead:
      return
        "You are not on a detached HEAD. Please switch to a detached HEAD before running this script."
    case .fileFetchError:
      return "Error fetching files."
    case .commitError:
      return "Error while committing files."
    case .cherryPickError(let commitHash):
      return
        "Cherry-pick failed for commit with hash \(commitHash). Please resolve conflicts and run 'git cherry-pick --continue'."
    }
  }
}

// Function to run git commands and capture their output
@discardableResult
func runGitCommand(_ command: String) throws -> String {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["bash", "-c", command]

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

// Function to commit files and return the commit hash
func commitFiles(_ files: [String], commitMessage: String) throws -> String {
  // Stage the files
  let filesToAdd = files.joined(separator: " ")
  try runGitCommand("git add \(filesToAdd)")

  // Commit the files
  try runGitCommand("git commit -m \"\(commitMessage)\"")

  // Get the commit hash of the latest commit
  let commitHash = try runGitCommand("git rev-parse HEAD")

  return commitHash
}

func main() throws {
  // Define the target branch where you want to cherry-pick the commits
  let targetBranch = "target-branch-name"

  // Ensure you're on a detached HEAD
  let branch = try runGitCommand("git rev-parse --abbrev-ref HEAD")
  if branch != "HEAD" {
    throw GitScriptError.notDetachedHead
  }

  // Get the list of tracked and untracked files
  guard
    let filesOutput = try? runGitCommand(
      "git ls-files --others --exclude-standard; git diff --name-only HEAD")
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
    let commitHash = try commitFiles(chunk, commitMessage: commitMsg)
    commitHashes.append(commitHash)
  }

  // Switch to the target branch
  try runGitCommand("git checkout \(targetBranch)")

  // Cherry-pick each of the chunked commits using the stored hashes
  for commitHash in commitHashes {
    do {
      try runGitCommand("git cherry-pick \(commitHash)")
    } catch {
      throw GitScriptError.cherryPickError(commitHash: commitHash)
    }
  }

  // Switch back to the detached HEAD state
  try runGitCommand("git checkout -")

  print("Successfully chunked commits and cherry-picked them to \(targetBranch).")
}

// Run the main function and handle errors
do {
  try main()
} catch let error as GitScriptError {
  print("Error: \(error.description)")
} catch {
  print("An unexpected error occurred: \(error)")
}
