import Foundation

/// A shard decoding accumulator.
public struct DataShardDecoder {
    private var currentShards: [Int: DataShard] = [:]
    public private(set) var state: State?
    public var isReadyToDecode: Bool {
        state?.remainingIndexes.isEmpty == true
    }

    public struct State {
        var groupID: UInt16
        /// The remaining shared indexes in the group that need to be added.
        public var remainingIndexes: Set<Int>
        /// The indexes of the shards that we have scanned so far.
        public var collectedIndexes: Set<Int>
        /// The total number of shards in the group.
        public var total: Int
    }

    public enum AddShardError: Error, Equatable {
        case inconsistentGroup
        case shardAlreadyExists

        /// Is this a non-critical error that can be resolved by scanning another code?
        public var canIgnoreError: Bool {
            switch self {
            case .inconsistentGroup, .shardAlreadyExists: true
            }
        }
    }

    public enum DecoderError: Error, Equatable {
        case missingShards
    }

    public init() {}

    /// Adds another shard to the decoder.
    ///
    /// Use `decodeData` when ready to extract all the shards.
    public mutating func add(shardData: Data) throws {
        let nextShard = try EncryptedVaultCoder().decode(dataShard: shardData)
        try verifyShardGroupIsConsistent(shard: nextShard)
        try verifyShardDoesNotExist(shard: nextShard)
        currentShards[nextShard.group.number] = nextShard

        let totalNumber = nextShard.group.totalNumber
        let collectedIndexes = currentShards.keys.reducedToSet()
        let remainingIndexes = (0 ..< totalNumber).reducedToSet().subtracting(collectedIndexes)
        state = State(
            groupID: nextShard.group.id,
            remainingIndexes: remainingIndexes,
            collectedIndexes: collectedIndexes,
            total: totalNumber,
        )
    }

    /// Extract the data based on the shards.
    public func decodeData() throws(DecoderError) -> Data {
        guard isReadyToDecode else { throw DecoderError.missingShards }
        let sortedShards = currentShards.sorted { $0.key < $1.key }.map(\.value)
        return sortedShards.reduce(into: Data()) { result, shard in
            result.append(shard.data)
        }
    }
}

// MARK: - Helpers

extension DataShardDecoder {
    /// Checks that the shard is not already in the decoder.
    private func verifyShardDoesNotExist(shard: DataShard) throws(AddShardError) {
        if currentShards[shard.group.number] != nil {
            throw AddShardError.shardAlreadyExists
        }
    }

    /// Checks that the import is using the same group number for all shards.
    /// If it isn't, then the shards do not compose a valid group.
    private func verifyShardGroupIsConsistent(shard: DataShard) throws(AddShardError) {
        guard let state else { return }
        if state.groupID != shard.group.id {
            throw AddShardError.inconsistentGroup
        }
    }
}
