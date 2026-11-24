import Foundation

/// A free-field estimate of sound-pressure level at a distance.
public struct SPLEstimate: Equatable, Sendable {
    /// Estimated sound-pressure level, in dB.
    public var splDB: Double
    /// Distance the estimate applies to, in metres.
    public var distanceM: Double
    /// Inverse-square (spherical spreading) attenuation relative to the reference distance, in dB.
    public var geometricAttenuationDB: Double
    /// ISO 9613-1 absorption over the path difference, in dB (0 when no frequency was given).
    public var atmosphericAbsorptionDB: Double
    /// Attenuation coefficient used, in dB/km, or `nil` when absorption was not applied.
    public var alphaDBPerKm: Double?
}

/// Free-field point-source propagation: inverse-square spreading plus optional
/// ISO 9613-1 absorption.
///
/// This is a first-order estimate. It does not model ground effect, reflections,
/// barriers, wind, turbulence or temperature gradients, and a train horn is a
/// broadband source, so a single-frequency absorption figure is only indicative.
/// It is not a substitute for a calibrated sound level meter.
public enum Propagation {
    /// A plain-language statement of the model's limits.
    public static let caveats = """
    Free-field point-source estimate only: inverse-square spreading, plus ISO 9613-1 \
    atmospheric absorption when a frequency is given. Does not include ground effect, \
    reflections, barriers, wind, turbulence, or temperature gradients. Not a substitute \
    for a calibrated sound level meter or a field measurement.
    """

    /// Inverse-square attenuation between two distances, in dB (positive means quieter).
    public static func geometricAttenuationDB(from referenceM: Double, to targetM: Double) throws -> Double {
        let r0 = try requirePositive("referenceDistanceM", referenceM)
        let r = try requirePositive("targetDistanceM", targetM)
        return 20.0 * log10(r / r0)
    }

    /// Estimates SPL at `targetDistanceM` from a free-field level measured at `referenceDistanceM`.
    ///
    /// - Parameters:
    ///   - sourceSPLDB: Level at the reference distance, in dB.
    ///   - referenceDistanceM: Distance at which `sourceSPLDB` was measured, in metres.
    ///   - targetDistanceM: Distance to estimate, in metres.
    ///   - frequencyHz: Optional pure-tone frequency for ISO 9613-1 absorption.
    ///   - atmosphere: Conditions for the absorption model.
    public static func spl(
        sourceSPLDB: Double,
        referenceDistanceM: Double,
        targetDistanceM: Double,
        frequencyHz: Double? = nil,
        atmosphere: Atmosphere = Atmosphere()
    ) throws -> SPLEstimate {
        let geometric = try geometricAttenuationDB(from: referenceDistanceM, to: targetDistanceM)
        var absorption = 0.0
        var alphaKm: Double?
        if let frequencyHz {
            let alpha = try ISO9613.alphaDBPerMetre(frequencyHz: frequencyHz, atmosphere: atmosphere)
            absorption = alpha * (targetDistanceM - referenceDistanceM)
            alphaKm = alpha * 1000.0
        }
        return SPLEstimate(
            splDB: sourceSPLDB - geometric - absorption,
            distanceM: targetDistanceM,
            geometricAttenuationDB: geometric,
            atmosphericAbsorptionDB: absorption,
            alphaDBPerKm: alphaKm
        )
    }

    /// Solves for the free-field distance at which the estimated SPL equals `targetSPLDB`.
    ///
    /// The level falls monotonically with distance, so a unique positive root exists;
    /// it is found by bisection in log-distance.
    public static func distance(
        forTargetSPLDB targetSPLDB: Double,
        sourceSPLDB: Double,
        referenceDistanceM: Double,
        frequencyHz: Double? = nil,
        atmosphere: Atmosphere = Atmosphere()
    ) throws -> SPLEstimate {
        let r0 = try requirePositive("referenceDistanceM", referenceDistanceM)
        var alpha = 0.0
        if let frequencyHz {
            alpha = try ISO9613.alphaDBPerMetre(frequencyHz: frequencyHz, atmosphere: atmosphere)
        }
        func residual(_ r: Double) -> Double {
            sourceSPLDB - 20.0 * log10(r / r0) - alpha * (r - r0) - targetSPLDB
        }
        var low = 1e-9
        var high = max(r0, 1.0)
        if residual(high) > 0 {
            var bracketed = false
            for _ in 0..<128 {
                high *= 2
                if residual(high) <= 0 { bracketed = true; break }
            }
            if !bracketed { throw TrainHornSPLError.noSolution }
        }
        for _ in 0..<80 {
            let mid = (low * high).squareRoot()
            if residual(mid) > 0 { low = mid } else { high = mid }
        }
        let r = (low * high).squareRoot()
        return try spl(sourceSPLDB: sourceSPLDB, referenceDistanceM: r0, targetDistanceM: r,
                       frequencyHz: frequencyHz, atmosphere: atmosphere)
    }

    /// Energetic sum of several levels in dB: 10·log10(Σ 10^(L/10)).
    ///
    /// Useful for a multi-chime horn whose chimes were measured separately.
    public static func combinedLevelDB(_ levels: [Double]) -> Double {
        guard !levels.isEmpty else { return -Double.infinity }
        return 10.0 * log10(levels.reduce(0) { $0 + pow(10.0, $1 / 10.0) })
    }
}
