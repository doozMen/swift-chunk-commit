import ArgumentParser
import Foundation

@main
struct Committer: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    version: "0.0.1",
    subcommands: [Chunk.self, SetupTest.self]
  )
}
