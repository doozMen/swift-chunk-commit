import Foundation

// Define errors that can occur during the script execution
public enum ChunkCommitterError: Error, CustomStringConvertible {
  case notDetachedHead
  case cliCommandFailed(forCommand: String, error: Swift.Error? = nil)
  case commitError
  case cherryPickError(commitHash: String)
  case bash(command: String, output: String)

  public var description: String {
    switch self {
    case .notDetachedHead:
      return
        "You are not on a detached HEAD. Please switch to a detached HEAD before running this script."
    case .cliCommandFailed(let command, .some(let error)):
      return "Cli command failed with error: \(error)."
    case .cliCommandFailed(let command, .none):
      return "Cli command failed."
    case .commitError:
      return "Error while committing files."
    case .cherryPickError(let commitHash):
      return
        "Cherry-pick failed for commit with hash \(commitHash). Please resolve conflicts and run 'git cherry-pick --continue'."
    case .bash(command: let command, output: let output):
      return """
      \(command) failed with output:
      \(output)
      """
    }
  }
}
