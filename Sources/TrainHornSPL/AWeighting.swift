import Foundation

/// IEC 61672-1 A-weighting.
public enum AWeighting {
    static let f1 = 20.6
    static let f2 = 107.7
    static let f3 = 737.9
    static let f4 = 12194.0
    static let offsetDB = 2.00

    /// A-weighting in decibels at a single frequency: 20·log10(R_A(f)) + 2.00 dB.
    public static func decibels(atFrequencyHz frequencyHz: Double) throws -> Double {
        let f = try requirePositive("frequencyHz", frequencyHz)
        let fsq = f * f
        let ra = (f4 * f4 * fsq * fsq) / (
            (fsq + f1 * f1) * ((fsq + f2 * f2) * (fsq + f3 * f3)).squareRoot() * (fsq + f4 * f4)
        )
        return 20.0 * log10(ra) + offsetDB
    }
}
