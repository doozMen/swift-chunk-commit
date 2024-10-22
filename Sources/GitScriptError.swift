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
