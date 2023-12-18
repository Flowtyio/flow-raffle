import Crypto

/// Defines a xorsift128+ pseudo random generator (PRG) struct used to generate random numbers given some
/// sourceOfRandomness and salt.
///
/// See FLIP 123 for more details: https://github.com/onflow/flips/blob/main/protocol/20230728-commit-reveal.md
/// And the onflow/random-coin-toss repo for implementation context: https://github.com/onflow/random-coin-toss
///
access(all) contract Xorshift128plus {

    /// While not limited to 128 bits of state, this PRG is largely informed by xorshift128+
    ///
    access(all) struct PRG {

        // The states below are of type Word64 (instead of UInt64) to prevent overflow/underflow as state evolves
        //
        access(all) var state0: Word64
        access(all) var state1: Word64

        /// Initializer for PRG struct
        ///
        /// @param sourceOfRandomness: The entropy bytes used to seed the PRG. It is recommended to use at least 16
        /// bytes of entropy.
        /// @param salt: The bytes used to salt the source of randomness
        ///
        init(sourceOfRandomness: [UInt8], salt: [UInt8]) {
            pre {
                sourceOfRandomness.length >= 16: "At least 16 bytes of entropy should be used"
            }

            let tmp: [UInt8] = sourceOfRandomness.concat(salt)
            // Hash is 32 bytes
            let hash: [UInt8] = Crypto.hash(tmp, algorithm: HashAlgorithm.SHA3_256)
            // Reduce the seed to 16 bytes
            let seed: [UInt8] = hash.slice(from: 0, upTo: 16)

            // Convert the seed bytes to two Word64 values for state initialization
            let segment0: Word64 = Xorshift128plus.bigEndianBytesToWord64(bytes: seed, start: 0)
            let segment1: Word64 = Xorshift128plus.bigEndianBytesToWord64(bytes: seed, start: 8)

            // Ensure the initial state is non-zero
            assert(segment0 != 0 || segment1 != 0, message: "PRG initial state must be initialized as non-zero")
            
            self.state0 = segment0
            self.state1 = segment1
        }

        /// Advances the PRG state and generates the next UInt64 value
        /// See https://arxiv.org/pdf/1404.0390.pdf for implementation details and reasoning for triplet selection.
        /// Note that state only advances when this function is called from a transaction. Calls from within a script
        /// will not advance state and will return the same value.
        ///
        /// @return The next UInt64 value
        ///
        access(all) fun nextUInt64(): UInt64 {
            var a: Word64 = self.state0
            let b: Word64 = self.state1

            self.state0 = b
            a = a ^ (a << 23) // a
            a = a ^ (a >> 17) // b
            a = a ^ b ^ (b >> 26) // c
            self.state1 = a

            let randUInt64: UInt64 = UInt64(Word64(a) + Word64(b))
            return randUInt64
        }
    }

    /// Helper function to convert an array of big endian bytes to Word64
    ///
    /// @param bytes: The bytes to convert
    /// @param start: The index of the first byte to convert
    ///
    /// @return The Word64 value
    ///
    access(contract) fun bigEndianBytesToWord64(bytes: [UInt8], start: Int): Word64 {
        pre {
            start + 8 <= bytes.length: "At least 8 bytes from the start are required for conversion"
        }
        var value: UInt64 = 0
        var i: Int = 0
        while i < 8 {
            value = value << 8 | UInt64(bytes[start + i])
            i = i + 1
        }
        return Word64(value)
    }
}