import ArgumentParser
import Foundation
import Logging

private let logger = Logger(label: "swift-chunk-commit:setup-test")

package struct SetupTest: AsyncParsableCommand {
  @Option private var numberOfFiles: Int = 50
  @Option private var targetBranch: String = "test-from-detached"

  package init() {}

  package func run() async throws {
    try await "git checkout -b \(targetBranch)".run()

    print("Switch to detached HEAD state")

    try await "git checkout --detach HEAD".run()

    print("Create files and add content")
    for i in 1...numberOfFiles {
      let fileName = "test_file_\(i).txt"
      let content = "This is file \(i)"
      try content.write(toFile: fileName, atomically: true, encoding: .utf8)
    }

    print("✅ test setup ready")
  }
}
