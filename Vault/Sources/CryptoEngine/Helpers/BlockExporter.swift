import Foundation

/// Exports a `payload` into distinct blocks of a given size, including an optional header.
public struct BlockExporter {
    /// The full data that is going to be generated into blocks.
    public let payload: Data
    /// Maximum size of the block, **including** the header.
    public let maxBlockSize: Int
    /// Header included in every block, given the current block context.
    public let blockHeader: ((BlockContext) -> Data)?
    /// The current number of block we are iterating on.
    private var currentBlockNumber = 0
    /// The current number of accumulated bytes the header has caused an offset of.
    private var currentOffsetHeaderBytes = 0

    public init(payload: Data, maxBlockSize: Int, blockHeader: ((BlockContext) -> Data)? = nil) {
        self.payload = payload
        self.maxBlockSize = maxBlockSize
        self.blockHeader = blockHeader
    }

    /// Indicates the header for this block is too large for the given block size and a block could not be generated.
    public struct HeaderTooLargeError: Error {
        public let maxSize: Int
        public let actualSize: Int
    }

    public struct BlockContext {
        /// The number block that this will become, starting from 0.
        public var blockNumber: Int
    }

    /// Generate the next block.
    ///
    /// - Returns: `nil` when there are no more blocks.
    public mutating func next() throws(HeaderTooLargeError) -> Data? {
        defer { currentBlockNumber += 1 }

        let header = try makeHeader(blockNumber: currentBlockNumber)
        let nextHeaderSize = header.count

        defer { currentOffsetHeaderBytes += nextHeaderSize }

        let start = min(maxBlockSize * currentBlockNumber - currentOffsetHeaderBytes, payload.count)
        let end = min(start + maxBlockSize - nextHeaderSize, payload.count)
        let blockRange = start ..< end

        guard blockRange.isNotEmpty else { return nil }

        return header + payload.subdata(in: blockRange)
    }

    private func makeHeader(blockNumber: Int) throws(HeaderTooLargeError) -> Data {
        let context = BlockContext(blockNumber: blockNumber)
        let header = blockHeader?(context) ?? Data()
        guard header.count < maxBlockSize else {
            throw HeaderTooLargeError(maxSize: maxBlockSize, actualSize: header.count)
        }
        return header
    }
}
