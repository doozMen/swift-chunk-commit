import ArgumentParser
import ChunkCommiter
import Foundation

@main
struct ChunkCommit: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    version: "0.0.1",
    subcommands: [Chunk.self, SetupTest.self]
  )
}
