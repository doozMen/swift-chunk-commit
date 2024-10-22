import Foundation

// Function to commit files and return the commit hash
func commitFiles(_ files: [String], commitMessage: String) async throws -> String {
  // Stage the files
  let filesToAdd = files.joined(separator: " ")
  try await "git add \(filesToAdd)".run()

  // Commit the files
  try await "git commit -m \"\(commitMessage)\"".run()

  // Get the commit hash of the latest commit
  let commitHash = try await "git rev-parse HEAD".run()

  return commitHash
}
