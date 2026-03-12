import Foundation

enum DeterministicHasher {
    private static let fnvOffsetBasis: UInt64 = 14_695_981_039_346_656_037
    private static let fnvPrime: UInt64 = 1_099_511_628_211

    static func fnv1a64Hex(_ string: String) -> String {
        fnv1a64Hex(Data(string.utf8))
    }

    static func fnv1a64Hex(_ data: Data) -> String {
        var hash = fnvOffsetBasis
        for byte in data {
            hash ^= UInt64(byte)
            hash = hash &* fnvPrime
        }

        return String(format: "%016llx", hash)
    }
}
